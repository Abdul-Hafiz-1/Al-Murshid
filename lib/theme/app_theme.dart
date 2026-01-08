import 'package:flutter/material.dart';

class AppColors {
  /// "Modern Mushaf" palette
  /// Background: warm cream, mimicking Quran paper
  static const Color background = Color(0xFFFFFBE8);

  /// Primary text: soft charcoal
  static const Color primaryText = Color(0xFF1F1F1F);

  /// Accent green for headers/icons
  static const Color accentGreen = Color(0xFF2E5C38);

  /// Gold accents for borders and verse markers
  static const Color gold = Color(0xFFC5A059);

  /// Subtle surface color for cards over the paper background
  static const Color surfaceLight = Color(0xFFFFFDF3);

  /// Dark mode baseline colors
  /// Soft black background for immersive reading
  static const Color darkBg = Color(0xFF151515);
  static const Color darkSurface = Color(0xFF1F1F1F);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accentGreen,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.primaryText,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.primaryText,
      background: AppColors.background,
      onBackground: AppColors.primaryText,
      error: Colors.red.shade700,
      onError: Colors.white,
      primaryContainer: AppColors.accentGreen.withOpacity(0.12),
      onPrimaryContainer: AppColors.accentGreen,
      secondaryContainer: AppColors.gold.withOpacity(0.12),
      onSecondaryContainer: AppColors.gold,
      surfaceContainerHighest: AppColors.surfaceLight,
      surfaceContainerHigh: AppColors.surfaceLight,
      surfaceContainer: AppColors.surfaceLight,
      surfaceContainerLow: AppColors.background,
      surfaceContainerLowest: AppColors.background,
      outline: AppColors.gold.withOpacity(0.6),
      outlineVariant: Colors.black.withOpacity(0.12),
      shadow: Colors.black.withOpacity(0.18),
      scrim: Colors.black.withOpacity(0.28),
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.gold,
    );

    return ThemeData(
      colorScheme: colorScheme,
      // English UI font – you can swap this for Montserrat/Proxima when added
      fontFamily: 'Montserrat',
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.gold.withOpacity(0.3),
            width: 0.6,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.primaryText,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        bodyMedium: TextStyle(
          color: AppColors.primaryText,
          height: 1.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accentGreen,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

}

