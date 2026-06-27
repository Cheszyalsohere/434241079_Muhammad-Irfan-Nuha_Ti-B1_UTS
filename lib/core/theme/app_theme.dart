/// Material 3 theme — "Quiet / Precise" (minimal-clean) aesthetic.
///
/// Off-white (light) / near-black (dark) solid backgrounds. Monochrome
/// ink buttons, hairline borders, one cobalt accent for interactivity.
/// No glassmorphism, no gradients. 10px card radius, 8px controls.
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
      surface: AppColors.surfaceLight,
      surfaceContainerLowest: AppColors.bgLight,
      surfaceContainerLow: AppColors.bgLight,
      surfaceContainer: AppColors.surfaceLight,
      surfaceContainerHighest: AppColors.surfaceAltLight,
    );
    return _build(
      scheme,
      dark: false,
      onSurface: const Color(0xFF1B1B1D),
      bg: AppColors.bgLight,
      surface: AppColors.surfaceLight,
      border: AppColors.borderLight,
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
      surfaceContainerLowest: AppColors.bgDark,
      surfaceContainerLow: AppColors.bgDark,
      surfaceContainer: AppColors.surfaceDark,
      surfaceContainerHighest: AppColors.surfaceAltDark,
    );
    return _build(
      scheme,
      dark: true,
      onSurface: const Color(0xFFF2F2F0),
      bg: AppColors.bgDark,
      surface: AppColors.surfaceDark,
      border: AppColors.borderDark,
    );
  }

  static ThemeData _build(
    ColorScheme scheme, {
    required bool dark,
    required Color onSurface,
    required Color bg,
    required Color surface,
    required Color border,
  }) {
    const double r = 8; // base control radius
    final Color ink = AppColors.inkButton(dark);
    final Color onInk = AppColors.onInkButton(dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppTextStyles.textTheme(onSurface),
      splashFactory: InkSparkle.splashFactory,

      // AppBar — transparent, left-aligned, no slab.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: onSurface),
      ),

      // Inputs — solid surface, hairline border, cobalt focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: onSurface.withValues(alpha: 0.5),
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: scheme.primary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),

      // Primary buttons — solid ink (monochrome), sharp.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: onInk,
          disabledBackgroundColor: ink.withValues(alpha: 0.35),
          disabledForegroundColor: onInk.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r),
          ),
          textStyle: AppTextStyles.titleMedium.copyWith(letterSpacing: 0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: onInk,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r),
          ),
          textStyle: AppTextStyles.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r),
          ),
          side: BorderSide(color: border, width: 1.2),
          textStyle: AppTextStyles.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards — solid, flat, hairline border.
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),

      // NavigationBar — solid, hairline top, monochrome with cobalt active.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: scheme.primary.withValues(alpha: 0.10),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return AppTextStyles.labelSmall.copyWith(
            fontSize: 11,
            color: selected ? scheme.primary : onSurface.withValues(alpha: 0.5),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color:
                selected ? scheme.primary : onSurface.withValues(alpha: 0.45),
            size: 22,
          );
        }),
      ),

      // FAB — solid ink, sharp.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: onInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        extendedTextStyle:
            AppTextStyles.titleMedium.copyWith(color: onInk),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: onInk),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? AppColors.surfaceAltDark
            : AppColors.surfaceAltLight,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        labelStyle: AppTextStyles.labelSmall.copyWith(color: onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: Colors.white,
        textStyle: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: onSurface.withValues(alpha: 0.6),
        titleTextStyle: AppTextStyles.titleMedium.copyWith(color: onSurface),
        subtitleTextStyle: AppTextStyles.bodyMedium,
      ),
    );
  }
}
