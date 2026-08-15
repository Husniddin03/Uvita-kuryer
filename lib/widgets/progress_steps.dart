import 'package:flutter/material.dart';

import '../theme.dart';

/// 4 bosqichli gorizontal stepper — birlashtiruvchi chiziqlar bilan.
/// Dizayn: aktiv_zakaz_do_konda (Progress Indicator)
class ProgressSteps extends StatelessWidget {
  /// Qaysi qadam faol (1..4). Tugallangan qadamlar ko'k, faol to'q ko'k.
  final int current;

  const ProgressSteps({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Asosiy chiziq
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          // Faol qism chiziq
          Positioned(
            left: 0,
            width: MediaQuery.of(context).size.width *
                ((current - 1).clamp(0, 3) / 3) *
                0.9,
            child: Container(height: 2, color: AppColors.primary),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 4; i++) _StepDot(index: i, current: current),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;

  const _StepDot({required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final isDone = index < current;
    final isActive = index == current;

    Color bg;
    Color fg;
    if (isDone) {
      bg = AppColors.success;
      fg = AppColors.onPrimary;
    } else if (isActive) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else {
      bg = AppColors.surface;
      fg = AppColors.textSecondary;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isDone || isActive
            ? null
            : Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                width: 2,
              ),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, size: 17, color: AppColors.onPrimary)
            : Text(
                '$index',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
      ),
    );
  }
}
