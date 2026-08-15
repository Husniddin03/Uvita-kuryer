import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/geocode_service.dart';
import '../services/permission_service.dart';
import '../theme.dart';
import '../utils/geo.dart';

/// Ichki navigatsiya xaritasi — dizayn: ichki_navigatsiya_xarita/
/// Frosted header + ko'k kuryer nuqtasi (pulse) + qizil manzil pini +
/// suzuvchi masofa/vaqt chipi + pastki panel.
class NavigationMapScreen extends StatefulWidget {
  final String address;
  final String region;
  final double? lat;
  final double? lng;
  final String? level;

  const NavigationMapScreen({
    super.key,
    required this.address,
    this.region = '',
    this.lat,
    this.lng,
    this.level,
  });

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
  final _mapCtrl = MapController();
  LatLng? _dest;
  LatLng? _user;
  RouteInfo? _route;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. DB koordinatalari
    if (widget.lat != null && widget.lng != null) {
      _applyDest(LatLng(widget.lat!, widget.lng!));
      _locateUser();
      return;
    }
    // 2. Geokodlash zanjiri
    var coords = await GeocodeService.geocode('${widget.address}, Uzbekistan');
    if (coords == null && widget.region.isNotEmpty) {
      coords = await GeocodeService.geocode('${widget.region}, Uzbekistan');
    }
    if (!mounted) return;
    if (coords != null) {
      _applyDest(LatLng(coords.lat, coords.lng));
    } else {
      _applyDest(const LatLng(41.3111, 69.2797));
    }
    _locateUser();
  }

  void _applyDest(LatLng dest) {
    setState(() => _dest = dest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapCtrl.move(dest, 14);
    });
  }

  Future<void> _locateUser() async {
    try {
      final granted = await PermissionService.ensureLocation();
      if (!granted) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      final user = LatLng(pos.latitude, pos.longitude);
      setState(() => _user = user);

      if (_dest != null) {
        _mapCtrl.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([user, _dest!]),
            padding: const EdgeInsets.all(60),
          ),
        );
        final route = await GeocodeService.route(
          GeoPoint(user.latitude, user.longitude),
          GeoPoint(_dest!.latitude, _dest!.longitude),
        );
        if (!mounted) return;
        if (route != null) setState(() => _route = route);
      } else {
        _mapCtrl.move(user, 15);
      }
    } catch (_) {
      // GPS yo'q
    }
  }

  Future<void> _openInExternalMaps() async {
    final q = widget.address.isNotEmpty
        ? Uri.encodeComponent(widget.address)
        : (widget.lat != null
            ? '${widget.lat},${widget.lng}'
            : 'Tashkent');
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeText = _route != null
        ? '${GeoUtils.kmLabel(_route!.distanceMeters / 1000)} · ${GeoUtils.etaLabel((_route!.durationSeconds / 60).round())}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Xarita ──
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _dest ?? const LatLng(41.3111, 69.2797),
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapTileUrl,
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'uz.uvita.courier',
                maxNativeZoom: 19,
                maxZoom: 19,
              ),
              if (_route != null && _route!.points.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.points
                          .map((p) => LatLng(p.lat, p.lng))
                          .toList(),
                      strokeWidth: 4,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              if (_dest != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _dest!,
                      width: 40,
                      height: 48,
                      alignment: Alignment.bottomCenter,
                      child: const _DestPin(),
                    ),
                  ],
                ),
              if (_user != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _user!,
                      width: 34,
                      height: 34,
                      child: const _CourierDot(),
                    ),
                  ],
                ),
            ],
          ),

          // ── Frosted header ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.arrow_back,
                              size: 22, color: AppColors.textMain),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MANZIL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.address.isNotEmpty
                                  ? widget.address
                                  : (widget.region.isNotEmpty
                                      ? widget.region
                                      : 'Manzil'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Masofa/vaqt chipi ──
          if (routeText != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: kCardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        routeText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Pastki panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(kCardRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mijoz kutyapti info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.info_outline,
                                  size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mijoz kutyapti',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Iltimos, manzilga yetib borgach aloqaga chiqing.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openInExternalMaps,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.outline, width: 1.5),
                                foregroundColor: AppColors.textMain,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(kButtonRadius),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Boshqa xaritada',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(kButtonRadius),
                                ),
                              ),
                              child: const Text('Yopish',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Qizil manzil pini (home ikonka bilan).
class _DestPin extends StatelessWidget {
  const _DestPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: 0.785398, // 45°
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: kCardShadow,
            ),
            child: const Center(
              child: Icon(Icons.home, size: 14, color: Colors.white),
            ),
          ),
        ),
        Container(
          width: 8,
          height: 3,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

/// Ko'k kuryer nuqtasi — pulslanuvchi halqa bilan.
class _CourierDot extends StatelessWidget {
  const _CourierDot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x44000000), blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
