import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/order_card.dart';
import '../widgets/segmented_control.dart';
import '../widgets/status_badge.dart';
import 'notifications_screen.dart';
import 'orders_map_screen.dart';

/// Zakazlar — dizayn: zakazlar_yangi/
/// Segmentli (Yangi zakazlar / Aktiv zakaz), daromadli kartalar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int? _acceptingId;
  int? _rejectingId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final orders = provider.orders;
    final loading = orders == null;
    final list = _tab == 0 ? provider.newOrders : provider.activeOrders;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                AppTopBar(
                  name: auth.profile?.name,
                  onBellTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                  extraActions: [
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OrdersMapScreen()),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.map_outlined,
                            size: 22, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OnlineChip(online: auth.profile?.isOnline ?? true),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SegmentedControl(
                    options: const ['Yangi zakazlar', 'Aktiv zakaz'],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (provider.error != null) _buildError(context, provider),
                if (loading)
                  ...List.generate(3, (_) => const _OrderSkeleton())
                else if (list.isEmpty)
                  _buildEmpty(_tab == 0)
                else
                  for (final o in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OrderCard(
                        order: o,
                        distanceKm: provider.metricsFor(o)?.km,
                        etaMin: provider.metricsFor(o)?.min,
                        accepting: _acceptingId == o.id,
                        rejecting: _rejectingId == o.id,
                        onAccept: _tab == 0 ? () => _accept(o) : null,
                        onReject: _tab == 0 ? () => _reject(o) : null,
                      ),
                    ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(Order order) async {
    // Daromad ko'rsatilgan tasdiqlash oynasi (dizayn talabi)
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: const Text('Zakazni qabul qilish',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        // Eslatma: tugmalar content ichida — AlertDialog.actions OverflowBar
        // bilan qoplanadi, unda Expanded ishlamaydi (ParentDataWidget xatosi).
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zakaz #${order.id} — ${order.address.region} → ${order.address.district.isNotEmpty ? order.address.district : order.address.street}',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('Kutilayotgan daromad',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(order.courierFee),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: AppColors.outline),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Bekor qilish',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Qabul qilish',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _acceptingId = order.id);
    try {
      await context.read<OrderProvider>().accept(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buyurtma qabul qilindi, yo\'lga chiqing')),
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

  Future<void> _reject(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zakazni rad etish',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Zakaz #${order.id} ni rad etasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rad etish'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _rejectingId = order.id);
    try {
      await context.read<OrderProvider>().reject(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tayinlov rad etildi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _rejectingId = null);
    }
  }

  Widget _buildError(BuildContext context, OrderProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => provider.refresh(),
            child: const Text('Qayta urinish',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isNewTab) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isNewTab ? Icons.local_shipping_outlined : Icons.directions_car_outlined,
              size: 34,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNewTab ? 'Yangi zakaz yo\'q' : 'Aktiv zakaz yo\'q',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isNewTab
                ? 'Yangi zakaz biriktirilganda bu yerda paydo bo\'ladi.'
                : 'Qabul qilingan zakazlar shu yerda ko\'rinadi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSkeleton extends StatelessWidget {
  const _OrderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 130,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 90,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
