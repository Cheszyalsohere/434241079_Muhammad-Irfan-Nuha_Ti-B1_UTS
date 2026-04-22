/// Typography tokens — display, headline, title, body, label variants.
///
/// Typeface is **Plus Jakarta Sans** (served at runtime by
/// `google_fonts`), chosen for its rounded, modern feel that pairs
/// cleanly with the glass/gradient aesthetic. We lean a bit heavier on
/// headlines (`w700`) and tighten letter-spacing on body to keep
/// readability crisp over the translucent surfaces.
///
/// Consumers should read styles from `Theme.of(context).textTheme` in
/// most cases; this class exists for places where a specific style is
/// needed without going through the theme lookup.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  /// Typeface name — kept as a constant for any debug/readme reference.
  /// Actual styles are produced through `GoogleFonts.plusJakartaSans(...)`.
  static const String fontFamily = 'Plus Jakarta Sans';

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.25,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.4,
      );

  /// Builder that returns a `TextTheme` configured for Material 3,
  /// respecting the surface text color passed in.
  static TextTheme textTheme(Color onSurface) {
    final Color muted = onSurface.withValues(alpha: 0.7);
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: onSurface),
      headlineMedium: headlineMedium.copyWith(color: onSurface),
      titleLarge: titleLarge.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      bodyLarge: bodyLarge.copyWith(color: onSurface),
      bodyMedium: bodyMedium.copyWith(color: muted),
      labelMedium: labelMedium.copyWith(color: muted),
      labelSmall: labelSmall.copyWith(color: muted),
    );
  }
}
