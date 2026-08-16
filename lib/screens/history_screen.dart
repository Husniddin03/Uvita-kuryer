import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/courier.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/order_detail_launcher.dart';
import '../widgets/status_badge.dart';
import 'notifications_screen.dart';

/// Tarix — dizayn: tarix/
/// Statistika kartasi + filtr chiplari + holat belgili ro'yxat.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Order>? _orders;
  String? _error;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _filter = 0; // 0=bugun, 1=hafta, 2=oy

  static const _filters = ['Bugun', 'Bu hafta', 'Bu oy'];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  /// Tab ochilganda yangi ma'lumot olish uchun (MainShell chaqiradi).
  Future<void> refresh() => _load(reset: true);

  Future<void> _load({bool reset = false}) async {
    try {
      final page = reset ? 1 : _page + 1;
      final list = await OrderService.getHistory(page: page);
      if (!mounted) return;
      setState(() {
        _orders = reset ? list : [...?_orders, ...list];
        _page = page;
        _hasMore = list.length >= 15;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  int _filterAmount(CourierEarnings? e) {
    if (e == null) return 0;
    switch (_filter) {
      case 1:
        return e.thisWeek;
      case 2:
        return e.thisMonth;
      default:
        return e.today;
    }
  }

  /// Ro'yxatni tanlangan davr bo'yicha filtrlaydi (chiplar endi ro'yxatga ham ta'sir qiladi).
  List<Order> _filtered(List<Order> orders) {
    final now = DateTime.now();
    DateTime? from;
    switch (_filter) {
      case 1: // Bu hafta — dushanbadan
        from = now.subtract(Duration(days: now.weekday - 1));
      case 2: // Bu oy
        from = DateTime(now.year, now.month);
      default:
        from = DateTime(now.year, now.month, now.day);
    }
    return orders.where((o) {
      final raw = o.deliveredAt ?? o.createdAt;
      final dt = DateTime.tryParse(raw);
      if (dt == null) return true;
      return !dt.isBefore(from!);
    }).toList();
  }

  /// Bugungi yetkazilganlar soni (yetkazilgan sanadan).
  int _todayCount(List<Order> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      final raw = o.deliveredAt ?? o.createdAt;
      final dt = DateTime.tryParse(raw);
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final earnings = context.watch<OrderProvider>().earnings;
    final orders = _orders;
    final loading = orders == null;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(reset: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppTopBar(
              name: auth.profile?.name,
              onBellTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Statistika ──
                const Text(
                  'Statistika',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: kCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daromad (${_filters[_filter].toLowerCase()})',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_up,
                                    size: 13, color: AppColors.success),
                                SizedBox(width: 3),
                                Text(
                                  'Daromad',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatMoney(_filterAmount(earnings)),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (orders != null && _filter == 0)
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 15, color: AppColors.success),
                            const SizedBox(width: 5),
                            Text(
                              '${_todayCount(orders)} ta yetkazilgan',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filtr chiplari ──
                Row(
                  children: [
                    for (var i = 0; i < _filters.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: _filters[i],
                          active: _filter == i,
                          onTap: () => setState(() => _filter = i),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Ro'yxat ──
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Qayta urinish',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                if (loading && _error == null)
                  ...List.generate(4, (_) => const _Skeleton())
                else if (orders == null || orders.isEmpty)
                  _buildEmpty()
                else ...[
                  for (final o in _filtered(orders))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryItem(order: o),
                    ),
                  if (_filtered(orders).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Bu davrda yetkazilgan buyurtma yo\'q',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton(
                        onPressed: _loadingMore
                            ? null
                            : () {
                                setState(() => _loadingMore = true);
                                _load().then((_) {
                                  if (mounted) {
                                    setState(() => _loadingMore = false);
                                  }
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side:
                              const BorderSide(color: AppColors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kButtonRadius),
                          ),
                        ),
                        child: Text(
                            _loadingMore ? 'Yuklanmoqda…' : 'Ko\'proq yuklash'),
                      ),
                    ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.history, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 14),
          Text(
            'Hali yetkazilgan buyurtma yo\'q',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Buyurtma yetkazib bo\'lgach tarixingiz shu yerda paydo bo\'ladi.',
            textAlign: TextAlign.center,
            style: TextStyle(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Order order;
  const _HistoryItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => OrderDetailLauncher.open(context, order.id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: kCardShadow,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zakaz #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatDateTime(order.deliveredAt ?? order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.forStatus(order.status),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      order.shortArea,
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
                    formatMoney(order.courierFee),
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
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 15,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 180,
            height: 13,
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
