import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../services/geocode_service.dart';
import '../services/permission_service.dart';
import '../theme.dart';

/// Buyurtma manzili xaritasi (OSM — bepul).
///
/// - Backend DB'da saqlangan lat/lng bo'lsa — to'g'ridan-to'g'ri ko'rsatiladi.
/// - Aks holda Nominatim geokodlash zanjiri (to'liq manzil → hudud → Toshkent).
/// - `showLocate=true` bo'lsa "Mening joylashuvim" + OSRM marshrut.
class DeliveryMap extends StatefulWidget {
  final String address;
  final String region;
  final double? lat;
  final double? lng;
  final String? level;
  final bool showLocate;
  final bool autoLocate;
  final double height;

  const DeliveryMap({
    super.key,
    required this.address,
    this.region = '',
    this.lat,
    this.lng,
    this.level,
    this.showLocate = true,
    this.autoLocate = false,
    this.height = 220,
  });

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final _mapCtrl = MapController();

  LatLng? _dest;
  String? _note;
  bool _locating = false;
  GeoPoint? _user;
  RouteInfo? _route;
  String? _geoErr;
  bool _permForever = false;

  double get _zoom {
    if (_dest == null) return 12;
    if (widget.level == 'region') return 12;
    return 16;
  }

  @override
  void initState() {
    super.initState();
    _init();
    // Jonli rejim: kuryer joylashuvi darhol ko'rsatiladi
    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
    }
  }

  Future<void> _init() async {
    // 1. DB koordinatalari — geokodlash shart emas
    if (widget.lat != null && widget.lng != null) {
      final dest = LatLng(widget.lat!, widget.lng!);
      _applyDest(
        dest,
        widget.level == 'region'
            ? 'Aniq manzil topilmadi — hudud markazi ko\'rsatilgan'
            : null,
      );
      return;
    }

    // 2. Geokodlash zanjiri
    var coords = await GeocodeService.geocode('${widget.address}, Uzbekistan');
    if (coords == null && widget.region.isNotEmpty) {
      coords = await GeocodeService.geocode('${widget.region}, Uzbekistan');
    }
    if (!mounted) return;

    if (coords != null) {
      _applyDest(
        LatLng(coords.lat, coords.lng),
        widget.region.isNotEmpty
            ? 'Aniq manzil topilmadi — hudud markazi ko\'rsatilgan'
            : null,
      );
    } else {
      _applyDest(
        const LatLng(41.3111, 69.2797), // Toshkent markazi
        'Manzilni xaritada aniqlab bo\'lmadi',
      );
    }
  }

  /// Tanlangan nuqtani xarita markaziga olib keladi va marker qo'yadi.
  void _applyDest(LatLng dest, String? note) {
    setState(() {
      _dest = dest;
      _note = note;
    });
    // Xarita markazini ham ko'chirish (initialCenter faqat birinchi build'da ishlaydi)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapCtrl.move(dest, _zoom);
    });
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _geoErr = null;
    });
    try {
      // 1. Avval ruxsatni tekshiramiz va so'raymiz
      final granted = await PermissionService.ensureLocation();
      if (!mounted) return;
      if (!granted) {
        final forever = await PermissionService.isLocationDeniedForever();
        if (!mounted) return;
        setState(() {
          _permForever = forever;
          _geoErr = forever
              ? 'Joylashuv ruxsati o\'chirilgan — sozlamalardan yoqing'
              : 'Joylashuv ruxsati rad etildi — "Mening joylashuvim" tugmasini qayta bosing';
        });
        return;
      }
      setState(() => _permForever = false);

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      if (!mounted) return;
      final user = GeoPoint(pos.latitude, pos.longitude);
      setState(() => _user = user);

      if (_dest != null) {
        _mapCtrl.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([_dest!, LatLng(user.lat, user.lng)]),
            padding: const EdgeInsets.all(48),
          ),
        );
        final route = await GeocodeService.route(user, _destPoint());
        if (!mounted) return;
        if (route != null) setState(() => _route = route);
      } else {
        _mapCtrl.move(LatLng(user.lat, user.lng), 15);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _geoErr = 'Joylashuvni aniqlab bo\'lmadi — GPS signalini tekshiring');
      Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _geoErr = null);
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  GeoPoint _destPoint() => GeoPoint(_dest!.latitude, _dest!.longitude);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _dest ?? const LatLng(41.3111, 69.2797),
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                // Sahifa scroll'ini o'g'irlamaslik uchun scroll wheel zoom o'chirilgan
                flags: InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapTileUrl,
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'uz.uvita.courier',
                maxNativeZoom: 19,
                maxZoom: 19,
              ),
              if (_dest != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _dest!,
                      width: 34,
                      height: 44,
                      alignment: Alignment.bottomCenter,
                      child: const _DestPin(),
                    ),
                  ],
                ),
              if (_user != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_user!.lat, _user!.lng),
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x55000000), blurRadius: 6),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_route != null && _route!.points.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.points
                          .map((p) => LatLng(p.lat, p.lng))
                          .toList(),
                      strokeWidth: 4,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
            ],
          ),

          // Eslatma chipi
          if (_note != null)
            Positioned(
              top: 10,
              left: 10,
              right: 60,
              child: _Chip(
                text: '⚠️ $_note',
                bg: Colors.white,
                fg: const Color(0xFFB45309),
              ),
            ),

          // Marshrut ma'lumoti
          if (_route != null)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: _Chip(
                  text:
                      '🛵 ${_fmtKm(_route!.distanceMeters)} · ${_fmtMin(_route!.durationSeconds)}',
                  bg: const Color(0xFF005AB3),
                  fg: Colors.white,
                ),
              ),
            ),

          // Geolokatsiya xatosi (+ sozlamalarga o'tish tugmasi)
          if (_geoErr != null)
            Positioned(
              bottom: 48,
              left: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _Chip(text: _geoErr!, bg: const Color(0xFFFFF1F0), fg: AppColors.danger)),
                  if (_permForever) ...[
                    const SizedBox(width: 6),
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: PermissionService.openSettings,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.settings, size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Sozlamalar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Mening joylashuvim
          if (widget.showLocate)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  elevation: 3,
                  child: InkWell(
                    onTap: _locating ? null : _locate,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_locating)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          else
                            const Icon(Icons.my_location,
                                size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            _locating ? 'Aniqlanmoqda…' : 'Mening joylashuvim',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtKm(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String _fmtMin(double sec) {
    final min = (sec / 60).round();
    if (min < 60) return '$min daq';
    return '${min ~/ 60} soat ${min % 60} daq';
  }
}

/// Manzil markeri (primary pin).
class _DestPin extends StatelessWidget {
  const _DestPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const SizedBox(
          width: 34,
          height: 44,
          child: Icon(Icons.location_pin, size: 38, color: AppColors.primaryDark),
        ),
        Positioned(
          top: 6,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
