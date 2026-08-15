import 'package:flutter/material.dart';

import '../theme.dart';

/// Holat belgisi (pill) — dizayn tizimi ranglari bilan.
class OrderBadge extends StatelessWidget {
  final String status;
  const OrderBadge({super.key, required this.status});

  static const _statuses = {
    'pending': ('Kutilmoqda', Color(0xFF8E8E93)),
    'paid': ('To\'landi', AppColors.primary),
    'confirmed': ('Tasdiqlandi', AppColors.primaryDark),
    'ready_to_deliver': ('Yangi', AppColors.primary),
    'delivering': ('Yetkazilmoqda', AppColors.warning),
    'delivered': ('Yetkazildi', AppColors.success),
    'delivery_issue': ('Muammo', AppColors.error),
    'cancelled': ('Bekor', Color(0xFF8E8E93)),
    'rejected': ('Rad etildi', AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _statuses[status] ?? (status, AppColors.textMuted);
    final label = entry.$1;
    final color = entry.$2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
