import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/delivery_map.dart';
import '../widgets/order_badge.dart';
import '../widgets/progress_steps.dart';
import 'navigation_map_screen.dart';
import 'pin_screen.dart';

/// Buyurtma detail — yetkazish oqimi (dizayn: aktiv_zakaz_do_kon_yangilangan
/// + yetkazib_berish). Holatga qarab bosqich ko'rsatiladi.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final Order? initial;
  const OrderDetailScreen({super.key, required this.orderId, this.initial});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initial;
    if (_order == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final order = await OrderService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _accept() async {
    final order = _order;
    if (order == null) return;
    setState(() => _busy = true);
    try {
      final updated = await context.read<OrderProvider>().accept(order);
      if (!mounted) return;
      setState(() => _order = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zakaz qabul qilindi, do\'kondan oling')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openNavMap() {
    final order = _order;
    if (order == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationMapScreen(
          address: order.address.full,
          region: order.address.region,
          lat: order.lat,
          lng: order.lng,
          level: order.geoLevel,
        ),
      ),
    );
  }

  void _openPin() {
    final order = _order;
    if (order == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PinScreen(order: order)),
    );
  }

  Future<void> _call(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^+\d]'), '');
    await launchUrl(Uri.parse('tel:$digits'));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Xatolik',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _load, child: const Text('Qayta urinish')),
            ],
          ),
        ),
      );
    }

    final order = _order;
    if (order == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isStoreStage = order.isNew;
    final isDelivering = order.isActive;
    final isDelivered = order.status == 'delivered';
    final isIssue = order.status == 'delivery_issue';

    final step = isStoreStage
        ? 1
        : isDelivering
            ? 2
            : isIssue
                ? 3
                : 4;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Header ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 20, color: AppColors.textMain),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '#ZAK-${order.id}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      OrderBadge(status: order.status),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                // Pastki sticky bar (Yetkazish joyiga keldim) ostida
                // qolib ketmasligi uchun yetarlicha padding
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 4 qadam progress
                    ProgressSteps(current: step),
                    const SizedBox(height: 20),

                    // ── Holat kartasi ──
                    if (isStoreStage)
                      const _StatusCard(
                        icon: Icons.storefront,
                        color: AppColors.warning,
                        bg: AppColors.warningBg,
                        title: 'Zakazni do\'kondan oling',
                        text:
                            'Manzilga borib, buyurtma raqamini ayting va mahsulotlarni qabul qiling.',
                      )
                    else if (isDelivering)
                      const _StatusCard(
                        icon: Icons.local_shipping,
                        color: AppColors.primaryDark,
                        bg: Color(0xFF0073E0),
                        title: 'Yetkazilmoqda — mijozga yo\'ldasiz',
                        text:
                            'Manzilga yetib borgach, quyidagi tugmani bosing.',
                        light: true,
                      )
                    else if (isDelivered)
                      const _StatusCard(
                        icon: Icons.check_circle,
                        color: AppColors.success,
                        bg: AppColors.successBg,
                        title: 'Yetkazildi 🎉',
                        text: 'Buyurtma muvaffaqiyatli yetkazildi.',
                      )
                    else if (isIssue)
                      const _StatusCard(
                        icon: Icons.error_outline,
                        color: AppColors.error,
                        bg: AppColors.errorBg,
                        title: 'Muammo holatida',
                        text:
                            'Buyurtma administrator hal qilishi uchun muammo holatiga o\'tkazildi.',
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 14),

                    // ── Xarita (yo'lda bo'lganda) ──
                    if (isDelivering || isStoreStage) ...[
                      SizedBox(
                        height: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DeliveryMap(
                            address: order.address.full,
                            region: order.address.region,
                            lat: order.lat,
                            lng: order.lng,
                            level: order.geoLevel,
                            showLocate: true,
                            autoLocate: isDelivering,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Do'kon / Mijoz kartasi ──
                    AppCard(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.store_outlined,
                            label: 'Do\'kon',
                            title: 'Uvita bozor',
                            subtitle: [
                              order.address.region,
                              order.address.district,
                            ].where((s) => s.isNotEmpty).join(', '),
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Mijoz',
                            title: 'Mijoz',
                            subtitle: order.address.full.isEmpty
                                ? order.phone
                                : order.address.full,
                          ),
                          if (order.deliveryTime.isNotEmpty) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.schedule_outlined,
                              label: 'Yetkazish vaqti',
                              title: order.deliveryTime,
                              subtitle: '',
                            ),
                          ],
                          if (order.courierNote.isNotEmpty) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.sticky_note_2_outlined,
                              label: 'Kuryerga izoh',
                              title: order.courierNote,
                              subtitle: '',
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mahsulotlar soni:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${order.items.length} ta paket',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Daromad ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 20, color: AppColors.success),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Kutilayotgan daromad',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(order.courierFee),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Aloqa gridi (yo'lda bo'lganda) ──
                    if (isDelivering) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.call,
                              color: AppColors.success,
                              label: 'Qo\'ng\'iroq\nqilish',
                              onTap: () => _call(order.phone),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.map_outlined,
                              color: AppColors.primary,
                              label: 'Xaritada\nochish',
                              onTap: _openNavMap,
                            ),
                          ),
                        ],
                      ),
                      if (order.phoneSecondary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionTile(
                                icon: Icons.call_outlined,
                                color: AppColors.warning,
                                label: 'Qo\'shimcha\nraqam',
                                onTap: () => _call(order.phoneSecondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'Xarita tashqi ilovada ochiladi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Mahsulotlar (qisqa) ──
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MAHSULOTLAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final it in order.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      it.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${it.quantity} × ${formatMoney(it.price)}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jami',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              Text(
                                formatMoney(order.grandTotal),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sticky tugmalar ──
            if (isStoreStage || isDelivering)
              StickyActionBar(
                child: isStoreStage
                    ? Column(
                        children: [
                          OutlineButton(
                            label: 'Do\'konni xaritada ochish',
                            icon: Icons.map_outlined,
                            onPressed: _openNavMap,
                            height: 50,
                          ),
                          const SizedBox(height: 10),
                          PrimaryButton(
                            label: 'Zakazni oldim',
                            icon: Icons.check_circle_outline,
                            loading: _busy,
                            onPressed: _accept,
                          ),
                        ],
                      )
                    : PrimaryButton(
                        label: 'Yetkazish joyiga keldim',
                        icon: Icons.place_outlined,
                        onPressed: _openPin,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kichik widgetlar
// ─────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String text;
  final bool light;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.text,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = light ? AppColors.onPrimary : color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
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
    );
  }
}
