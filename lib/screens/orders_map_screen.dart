import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/permission_service.dart';
import '../theme.dart';
import '../utils/geo.dart';
import '../widgets/segmented_control.dart';

/// Zakazlar xarita ko'rinishi — dizayn: zakazlar_xarita_ko_rinishi/
class OrdersMapScreen extends StatefulWidget {
  const OrdersMapScreen({super.key});

  @override
  State<OrdersMapScreen> createState() => _OrdersMapScreenState();
}

class _OrdersMapScreenState extends State<OrdersMapScreen> {
  int _tab = 0;
  final _mapCtrl = MapController();
  LatLng? _user;
  int? _acceptingId;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      final granted = await PermissionService.ensureLocation();
      if (!granted) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      if (!mounted) return;
      setState(() => _user = LatLng(pos.latitude, pos.longitude));
      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 13);
    } catch (_) {
      _mapCtrl.move(const LatLng(41.3111, 69.2797), 12);
    }
  }

  List<Order> _orders(OrderProvider p) =>
      _tab == 0 ? p.newOrders : p.activeOrders;

  Future<void> _accept(Order order) async {
    setState(() => _acceptingId = order.id);
    try {
      await context.read<OrderProvider>().accept(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buyurtma qabul qilindi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = _orders(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Xarita ──
          FlutterMap(
            mapController: _mapCtrl,
            options: const MapOptions(
              initialCenter: LatLng(41.3111, 69.2797),
              initialZoom: 12,
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
              if (_user != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _user!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x660A84FF),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final o in orders)
                    if (o.lat != null && o.lng != null)
                      Marker(
                        point: LatLng(o.lat!, o.lng!),
                        width: 64,
                        height: 40,
                        alignment: Alignment.bottomCenter,
                        child: _OrderPin(
                          label: formatShort(o.courierFee),
                          onTap: () => _focusOrder(o),
                        ),
                      ),
                ],
              ),
            ],
          ),

          // ── Header overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xF2F5F5F7), Color(0x00F5F5F7)],
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: kCardShadow,
                      ),
                      child: const Icon(Icons.arrow_back,
                          size: 20, color: AppColors.textMain),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SegmentedControl(
                      options: const ['Yangi zakazlar', 'Aktiv zakaz'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Ro'yxat ko'rinishiga qaytish
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: kCardShadow,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.format_list_bulleted,
                          size: 18, color: AppColors.textMain),
                      padding: EdgeInsets.zero,
                      tooltip: 'Ro\'yxat',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom sheet ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.32,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(kCardRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Yaqin zakazlar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Barchasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gorizontal mini-kartalar
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(
                            child: Text(
                              'Bu bo\'limda zakaz yo\'q',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              for (final o in orders)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _MiniCard(
                                    order: o,
                                    distance: provider.metricsFor(o)?.km,
                                    accepting: _acceptingId == o.id,
                                    onAccept:
                                        o.isNew ? () => _accept(o) : null,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _focusOrder(Order o) {
    if (o.lat == null || o.lng == null) return;
    _mapCtrl.move(LatLng(o.lat!, o.lng!), 15);
  }
}

/// To'q sariq zakaz pini — narx bilan.
class _OrderPin extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OrderPin({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kCardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_mall_outlined,
                    size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Pin uchburchagi
          CustomPaint(
            size: const Size(14, 6),
            painter: _PinArrowPainter(AppColors.warning),
          ),
        ],
      ),
    );
  }
}

class _PinArrowPainter extends CustomPainter {
  final Color color;
  _PinArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bottom sheet ichidagi mini-karta.
class _MiniCard extends StatelessWidget {
  final Order order;
  final double? distance;
  final bool accepting;
  final VoidCallback? onAccept;

  const _MiniCard({
    required this.order,
    this.distance,
    this.accepting = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#ORD-${order.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.shortArea,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (order.isNew)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_new,
                          size: 12, color: AppColors.warning),
                      SizedBox(width: 3),
                      Text(
                        'Yangi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.navigation_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                distance != null
                    ? '${GeoUtils.kmLabel(distance!)} · ~${GeoUtils.etaMinutes(distance!)} min'
                    : '—',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMoney(order.courierFee),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (onAccept != null)
                FilledButton(
                  onPressed: accepting ? null : onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: accepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Qabul qilish',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
