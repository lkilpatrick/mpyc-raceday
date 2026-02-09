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

  // Dark mode variants for on-water sun glare
  static ThemeData get mobileDarkTheme =>
      _buildDarkTheme(dense: false);
  static ThemeData get mobileDarkHighContrast =>
      _buildDarkTheme(dense: false, highContrast: true);

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
      cardTheme: const CardThemeData(
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

  static ThemeData _buildDarkTheme({
    required bool dense,
    bool highContrast = false,
  }) {
    final fg = highContrast ? Colors.white : Colors.white70;
    final bg = highContrast ? Colors.black : const Color(0xFF121212);
    final cardColor = highContrast ? const Color(0xFF1A1A1A) : const Color(0xFF1E1E1E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF5B9BD5),
        secondary: AppColors.secondary,
        surface: bg,
        error: Colors.red.shade300,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Inter',
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: cardColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: dense,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
      textTheme: highContrast
          ? ThemeData.dark().textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              )
          : null,
    );
  }
}
