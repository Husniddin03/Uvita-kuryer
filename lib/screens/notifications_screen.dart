import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/order_detail_launcher.dart';

/// Bildirishnomalar markazi — 🔔 tugmasi ochadi.
/// Backend: GET /courier/notifications, PUT /courier/notifications/{id}/read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await OrderService.getNotifications();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = (item['id'] ?? 0) as int;
    final isRead = (item['is_read'] ?? false) as bool;
    // O'qilgan deb belgilash
    if (!isRead) {
      try {
        await OrderService.markNotificationRead(id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        final list = _items;
        if (list != null) {
          for (final it in list) {
            if (it['id'] == id) it['is_read'] = true;
          }
        }
      });
    }
    // Zakaz haqida bo'lsa — detailni ochamiz
    final data = item['data'];
    final orderId = data is Map ? data['order_id'] : null;
    if (orderId != null && mounted) {
      OrderDetailLauncher.open(context, orderId as int);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order_assigned':
        return Icons.local_shipping_outlined;
      case 'order_rescheduled':
        return Icons.update;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'payout_paid':
        return Icons.payments_outlined;
      case 'support_updated':
        return Icons.support_agent;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'order_assigned':
        return AppColors.primary;
      case 'order_rescheduled':
        return AppColors.warning;
      case 'order_cancelled':
        return AppColors.error;
      case 'payout_paid':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final loading = items == null;

    return Scaffold(
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
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 20, color: AppColors.textMain),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bildirishnomalar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
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
                            onPressed: _load,
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  if (loading && _error == null)
                    ...List.generate(4, (_) => const _Skeleton())
                  else if (items == null || items.isEmpty)
                    _buildEmpty()
                  else
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationTile(
                          title: (item['title'] ?? '') as String,
                          body: (item['body'] ?? '') as String,
                          createdAt: (item['created_at'] ?? '') as String,
                          type: (item['type'] ?? '') as String,
                          isRead: (item['is_read'] ?? false) as bool,
                          icon: _iconFor((item['type'] ?? '') as String),
                          color: _colorFor((item['type'] ?? '') as String),
                          onTap: () => _open(item),
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

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 14),
          Text(
            'Bildirishnomalar yo\'q',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Yangi zakaz, hisob-kitob va xabarlar shu yerda ko\'rinadi.',
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

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String createdAt;
  final String type;
  final bool isRead;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    required this.isRead,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRead ? AppColors.surface : AppColors.infoBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? AppColors.outlineVariant.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(createdAt),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
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
            width: 160,
            height: 15,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 220,
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
