import 'package:flutter/material.dart';

import '../theme.dart';

/// Holat belgisi (pill) — dizayn tizimi: 12% fon + to'liq rangli matn.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Buyurtma holatiga mos belgi.
  factory StatusBadge.forStatus(String status) {
    switch (status) {
      case 'ready_to_deliver':
        return const StatusBadge(
          label: 'Yangi',
          color: AppColors.primary,
          icon: Icons.fiber_new,
        );
      case 'delivering':
        return const StatusBadge(
          label: 'Yo\'lda',
          color: AppColors.warning,
          icon: Icons.local_shipping_outlined,
        );
      case 'delivered':
        return const StatusBadge(
          label: 'Yetkazildi',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'delivery_issue':
        return const StatusBadge(
          label: 'Muammo',
          color: AppColors.error,
          icon: Icons.error_outline,
        );
      case 'rejected':
        return const StatusBadge(
          label: 'Rad etildi',
          color: AppColors.error,
          icon: Icons.cancel,
        );
      case 'cancelled':
        return const StatusBadge(
          label: 'Bekor',
          color: Color(0xFF8E8E93),
          icon: Icons.cancel_outlined,
        );
      default:
        return StatusBadge(
          label: status,
          color: AppColors.textMuted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Onlayn holat chipi — yashil pill, pulslanuvchi nuqta.
class OnlineChip extends StatelessWidget {
  final bool online;
  const OnlineChip({super.key, this.online = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            online
                ? 'Online — zakaz qabul qilishga tayyor'
                : 'Oflayn — yangi zakazlar kelmaydi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: online ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
