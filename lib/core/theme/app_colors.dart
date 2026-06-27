/// Brand + semantic color tokens — "Quiet / Precise" palette.
///
/// Direction: minimal & clean (Linear / Notion / Vercel lineage).
/// Off-white surfaces in light mode, near-black in dark. Chrome stays
/// monochrome — solid ink buttons, hairline borders — and a single
/// restrained cobalt accent carries interactivity (links, focus,
/// active states). Status/priority tokens stay semantic so badges keep
/// their meaning.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Accent (the one pop of colour) ─────────────────────────────────
  /// Cobalt — used for links, focus rings, selected nav, ticket IDs.
  /// Mapped to `colorScheme.primary` so existing accent call-sites get
  /// a refined, consistent highlight without per-widget edits.
  static const Color primary = Color(0xFF3056D3);
  static const Color primaryDark = Color(0xFF7E96FF);

  /// Amber — in-progress / warning.
  static const Color secondary = Color(0xFFD97706);

  /// Green — resolved / success.
  static const Color tertiary = Color(0xFF059669);

  /// Destructive.
  static const Color error = Color(0xFFDC2626);

  // ── Ink (solid primary buttons) ────────────────────────────────────
  /// Near-black button in light mode; flips to near-white in dark so the
  /// solid action surface stays legible against the page.
  static Color inkButton(bool dark) =>
      dark ? const Color(0xFFFAFAF8) : const Color(0xFF18181B);
  static Color onInkButton(bool dark) =>
      dark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);

  // ── Backgrounds ────────────────────────────────────────────────────
  /// Warm off-white page background (Notion-ish).
  static const Color bgLight = Color(0xFFFBFBFA);

  /// Near-black page background.
  static const Color bgDark = Color(0xFF0A0A0B);

  // ── Surfaces (cards, sheets) ───────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF161618);

  /// Secondary surface (filled chips, skeletons, subtle fills).
  static const Color surfaceAltLight = Color(0xFFF3F3F0);
  static const Color surfaceAltDark = Color(0xFF202023);

  // ── Borders (hairline) ─────────────────────────────────────────────
  static Color borderLight = const Color(0xFF18181B).withValues(alpha: 0.08);
  static Color borderDark = Colors.white.withValues(alpha: 0.09);

  // ── Elevation: "subtle tactile" rest shadow ────────────────────────
  /// A whisper of shadow under resting cards (per DESIGN.md elevation).
  /// Light mode only — in dark mode depth comes from the border + tonal
  /// step, so a shadow on near-black would be invisible noise.
  static List<BoxShadow> restShadow(bool dark) => dark
      ? const <BoxShadow>[]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A18181B), // ink @ ~0.04
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0D18181B), // ink @ ~0.05
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ];

  // ── Aliases so legacy "glass" call-sites keep compiling ────────────
  static Color get glassSurfaceLight => surfaceLight;
  static Color get glassSurfaceDark => surfaceDark;
  static Color get glassBorderLight => borderLight;
  static Color get glassBorderDark => borderDark;

  // ── Gradient stubs (GradientBackground still imports these) ─────────
  static const Color gradientLight1 = bgLight;
  static const Color gradientLight2 = bgLight;
  static const Color gradientLight3 = bgLight;
  static const Color gradientDark1 = bgDark;
  static const Color gradientDark2 = bgDark;
  static const Color gradientDark3 = bgDark;

  // ── Neutrals ───────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // ── Status tokens ──────────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF2563EB);
  static const Color statusInProgress = Color(0xFFD97706);
  static const Color statusResolved = Color(0xFF059669);
  static const Color statusClosed = Color(0xFF6B7280);

  // ── Priority tokens ────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF9CA3AF);
  static const Color priorityMedium = Color(0xFF2563EB);
  static const Color priorityHigh = Color(0xFFD97706);
  static const Color priorityUrgent = Color(0xFFDC2626);

  static Color statusColor(String status) => switch (status) {
        'open' => statusOpen,
        'in_progress' => statusInProgress,
        'resolved' => statusResolved,
        'closed' => statusClosed,
        _ => neutral400,
      };

  static Color priorityColor(String priority) => switch (priority) {
        'low' => priorityLow,
        'medium' => priorityMedium,
        'high' => priorityHigh,
        'urgent' => priorityUrgent,
        _ => neutral400,
      };
}
