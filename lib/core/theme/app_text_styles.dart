/// Typography tokens — Schibsted Grotesk × Hanken Grotesk × JetBrains Mono.
///
/// Schibsted Grotesk (tight, characterful grotesque) carries display and
/// headings with negative tracking for a premium, editorial feel.
/// Hanken Grotesk (clean, highly legible) handles body and labels.
/// JetBrains Mono renders ticket IDs, KPI numbers, and timestamps — the
/// "data" voice of the app.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  // ── Display ────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.schibstedGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.2,
      );

  // ── Headlines ──────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.schibstedGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.7,
      );

  static TextStyle get headlineMedium => GoogleFonts.schibstedGrotesk(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.5,
      );

  // ── Titles ─────────────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.schibstedGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get titleMedium => GoogleFonts.schibstedGrotesk(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.1,
      );

  // ── Body (Hanken Grotesk) ──────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.hankenGrotesk(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.55,
        letterSpacing: 0,
      );

  static TextStyle get bodyMedium => GoogleFonts.hankenGrotesk(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      );

  // ── Labels ─────────────────────────────────────────────────────────
  static TextStyle get labelMedium => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.3,
      );

  // ── Monospace — ticket IDs, KPI values, timestamps ─────────────────
  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: -1.0,
      );

  static TextStyle get monoMedium => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
      );

  /// "Eyebrow" — tiny uppercase tracked label used above section titles.
  static TextStyle get eyebrow => GoogleFonts.jetBrainsMono(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 1.5,
      );

  /// Builds the Material `TextTheme` for both light and dark modes.
  static TextTheme textTheme(Color onSurface) {
    final Color muted = onSurface.withValues(alpha: 0.55);
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: onSurface),
      displayMedium: headlineLarge.copyWith(color: onSurface),
      headlineLarge: headlineLarge.copyWith(color: onSurface),
      headlineMedium: headlineMedium.copyWith(color: onSurface),
      titleLarge: titleLarge.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      titleSmall: titleMedium.copyWith(
        color: onSurface,
        fontSize: 13,
      ),
      bodyLarge: bodyLarge.copyWith(color: onSurface),
      bodyMedium: bodyMedium.copyWith(color: muted),
      bodySmall: bodyMedium.copyWith(color: muted, fontSize: 12),
      labelLarge: labelMedium.copyWith(color: onSurface),
      labelMedium: labelMedium.copyWith(color: muted),
      labelSmall: labelSmall.copyWith(color: muted),
    );
  }
}
