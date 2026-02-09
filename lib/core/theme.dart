import 'package:flutter/material.dart';



class AppColors {

  const AppColors._();

  // MPYC Navy — primary brand color from club website
  static const Color primary = Color(0xFF1B3A5C);
  // Darker navy for sidebar / hover states
  static const Color primaryDark = Color(0xFF0F2440);
  // Bear-flag red from the burgee
  static const Color secondary = Color(0xFFCF4520);
  // Gold accent — from burgee star / club trim
  static const Color accent = Color(0xFFC9A94E);
  // Warm off-white background
  static const Color surface = Color(0xFFF5F5F0);
  // Sidebar background
  static const Color sidebarBg = Color(0xFF152E4A);
  // Sidebar selected item highlight
  static const Color sidebarSelected = Color(0xFF1F4268);
  // Subtle border / divider
  static const Color divider = Color(0xFFE0DDD5);

}



class AppTheme {

  const AppTheme._();



  static ThemeData get mobileTheme => _buildTheme(dense: false);

  static ThemeData get mobileDarkTheme => _buildDarkTheme(dense: false);

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



  static ThemeData _buildDarkTheme({required bool dense}) {

    final base = ThemeData(

      useMaterial3: true,

      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(

        primary: AppColors.primary,

        secondary: AppColors.secondary,

        surface: const Color(0xFF1E1E1E),

        error: AppColors.secondary,

      ),

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

      cardTheme: CardThemeData(

        surfaceTintColor: Colors.grey.shade900,

        color: Colors.grey.shade900,

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

        style: TextButton.styleFrom(foregroundColor: AppColors.accent),

      ),

    );

  }

}
