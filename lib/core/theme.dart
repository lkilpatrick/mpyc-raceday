import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1B3A5C);
  static const Color secondary = Color(0xFFD32F2F);
  static const Color accent = Color(0xFFC9A94E);
  static const Color surface = Color(0xFFF5F5F0);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get mobileTheme => _buildTheme(dense: false);
  static ThemeData get webTheme => _buildTheme(dense: true);

  static ThemeData _buildTheme({required bool dense}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.secondary,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'Inter',
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: dense
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardTheme(
        surfaceTintColor: Colors.white,
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: dense,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }
}
