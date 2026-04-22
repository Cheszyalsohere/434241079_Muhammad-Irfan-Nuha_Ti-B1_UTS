/// Material 3 theme definitions (light + dark) with custom `ColorScheme`.
///
/// Tuned for the glass/gradient aesthetic:
///   • `scaffoldBackgroundColor` is transparent so the app-level
///     [GradientBackground] shows through every route.
///   • `AppBarTheme` is transparent + elevation 0 so bars float over
///     the gradient without a slab behind them.
///   • Cards and inputs use translucent fills on top of a hairline
///     border — same language as [GlassContainer]/[GlassCard].
///   • Radii follow the scale: sm 10, md 16, lg 24 — buttons and
///     inputs at 16, cards at 20, chips stay pill (999).
///
/// Call [AppTheme.light] / [AppTheme.dark] from `MaterialApp`; the
/// scheme is seeded from [AppColors.primary] then overridden with
/// explicit secondary/tertiary/error values.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      surface: Colors.white,
    );
    return _buildTheme(
      scheme,
      onSurface: AppColors.neutral900,
      glassSurface: AppColors.glassSurfaceLight,
      glassBorder: AppColors.glassBorderLight,
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      surface: AppColors.neutral900,
    );
    return _buildTheme(
      scheme,
      onSurface: AppColors.neutral50,
      glassSurface: AppColors.glassSurfaceDark,
      glassBorder: AppColors.glassBorderDark,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme scheme, {
    required Color onSurface,
    required Color glassSurface,
    required Color glassBorder,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Transparent so `GradientBackground` bleeds through every route.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppTextStyles.textTheme(onSurface),

      // Transparent AppBar — bars float over the gradient.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: onSurface),
      ),

      // Glass-y input fields. Rounded 16 (md token), translucent fill,
      // hairline border that matches the glass language.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Primary buttons — rounded 16, taller touch target.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.titleMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.titleMedium,
        ),
      ),

      // Cards default to the glass look — `GlassCard` is still the
      // preferred way to get the blur, but stock `Card` now at least
      // reads correctly over the gradient.
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: glassSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glassBorder),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: glassBorder),
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: onSurface),
      ),

      dividerTheme: DividerThemeData(
        color: glassBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
