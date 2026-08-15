import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme.dart';
import '../utils/geo.dart';
import 'app_buttons.dart';
import 'order_badge.dart';
import 'order_detail_launcher.dart';
import 'status_badge.dart';

/// Zakaz kartasi — dizayn: zakazlar_yangi (Order Card)
/// Yangi (ready_to_deliver): ko'k chap chiziq, Rad etish / Qabul qilish.
/// Aktiv (delivering): bosilganda detail ochiladi.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool accepting;
  final bool rejecting;

  /// Masofa (km) va ETA (daq) — kuryer joylashuvidan hisoblangan (ixtiyoriy).
  final double? distanceKm;
  final int? etaMin;

  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.accepting = false,
    this.rejecting = false,
    this.distanceKm,
    this.etaMin,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = order.isNew;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Yangi zakaz uchun ko'k chap chiziq
          if (isNew)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: AppColors.primary),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isNew
                  ? null
                  : () => OrderDetailLauncher.open(context, order.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Zakaz #${order.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        if (isNew)
                          const StatusBadge(
                            label: 'Yangi',
                            color: AppColors.primary,
                            icon: Icons.fiber_new,
                          )
                        else
                          OrderBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Yo'nalish ──
                    _RouteLine(label: order.routeLabel),
                    const SizedBox(height: 12),

                    // ── Stats: masofa + vaqt ──
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.route_outlined,
                          label: distanceKm != null
                              ? GeoUtils.kmLabel(distanceKm!)
                              : '— km',
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 1,
                          height: 16,
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        _StatChip(
                          icon: Icons.schedule_outlined,
                          label: etaMin != null
                              ? '$etaMin daqiqa'
                              : '— daq',
                        ),
                        const Spacer(),
                        Container(
                          width: 1,
                          height: 16,
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        _StatChip(
                          icon: Icons.shopping_bag_outlined,
                          label: '${order.items.length} ta',
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // ── Daromad ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sof daromad:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          formatMoney(order.courierFee),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),

                    // ── Tugmalar ──
                    if (isNew && onAccept != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DangerOutlineButton(
                              label: 'Rad etish',
                              height: 50,
                              loading: rejecting,
                              onPressed: onReject,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: PrimaryButton(
                              label: 'Qabul qilish',
                              height: 50,
                              loading: accepting,
                              onPressed: onAccept,
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isNew) ...[
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Batafsil',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios,
                              size: 13, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yo'nalish chizig'i — radio nuqta → chiziq → manzil pin.
class _RouteLine extends StatelessWidget {
  final String label;
  const _RouteLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            const Icon(Icons.radio_button_checked,
                size: 16, color: AppColors.primary),
            Container(
              width: 1.5,
              height: 22,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            const Icon(Icons.location_on_outlined,
                size: 16, color: AppColors.primary),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
