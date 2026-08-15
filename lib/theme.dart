import 'package:flutter/material.dart';

/// Courier OS — iOS/macOS uslubidagi dizayn tizimi.
/// Dizayn spetsifikatsiyasi: `stitch_minimalist_mac_style/courier_os/DESIGN.md`
class AppColors {
  AppColors._();

  // ── Asosiy (Apple HIG) ──────────────────────────────────────
  /// Primary — "Happy Path" tugmalar, faol tab holatlari
  static const primary = Color(0xFF0A84FF);
  static const primaryDark = Color(0xFF005AB3);
  static const primaryLight = Color(0xFFD6E3FF);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Fonda (Level 0)
  static const background = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFDADADA);
  static const surfaceContainerLow = Color(0xFFF3F3F3);
  static const surfaceContainer = Color(0xFFEEEEEE);
  static const surfaceContainerHigh = Color(0xFFE8E8E8);

  /// Matn
  static const textMain = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF636366);
  static const textSecondary = Color(0xFF3C3C43);

  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC0C6D6);

  // ── Semantik ───────────────────────────────────────────────
  static const success = Color(0xFF34C759);
  static const successBg = Color(0x1F34C759); // 12% opacity
  static const warning = Color(0xFFFF9500);
  static const warningBg = Color(0x1FFF9500);
  static const error = Color(0xFFFF3B30);
  static const errorBg = Color(0x1FFF3B30);
  static const infoBg = Color(0x1F0A84FF);

  // ── Eski nomlar (qulaylik uchun alias) ─────────────────────
  static const white = Color(0xFFFFFFFF);
  static const danger = error;
  static const warn = warning;
}

/// Karta soyasi — Level 1: `0 2px 12px rgba(0,0,0,0.06)`
const List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 12,
    offset: Offset(0, 2),
  ),
];

/// Karta radiusi (Apple "squircle")
const double kCardRadius = 20;

/// Tugma radiusi
const double kButtonRadius = 14;

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(
          color: AppColors.textMain,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kButtonRadius),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kButtonRadius),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kButtonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kButtonRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textMain,
        contentTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(kCardRadius)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),
    );
  }
}

/// Sonni so'm formatida chiqarish: 15000 → "15 000 so'm"
String formatMoney(int v) {
  final s = v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  return '$s so\'m';
}

/// Qisqa raqam: 15000 → "15k", 1200000 → "1.2m"
String formatShort(int v) {
  if (v >= 1000000) {
    final m = (v / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '${m.replaceAll('.', ',')}m';
  }
  if (v >= 1000) {
    final k = (v / 1000).toStringAsFixed(0);
    return '${k}k';
  }
  return '$v';
}

/// Kun/vaqt: ISO string → "14.08.2026, 14:30"
String formatDateTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso.isEmpty ? '—' : iso;
  String p(int x) => x.toString().padLeft(2, '0');
  return '${p(dt.day)}.${p(dt.month)}.${dt.year}, ${p(dt.hour)}:${p(dt.minute)}';
}

/// Kun: ISO string → "14.08.2026"
String formatDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  String p(int x) => x.toString().padLeft(2, '0');
  return '${p(dt.day)}.${p(dt.month)}.${dt.year}';
}
