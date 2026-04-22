/// Brand + semantic color tokens for the E-Ticketing Helpdesk app.
///
/// All colors referenced by widgets must come from here — never inline
/// hex literals in UI code. Status and priority maps are the single
/// source of truth for chip/badge colors.
///
/// Palette direction: "iOS Control Center × Windows 11 Fluent" — a
/// vibrant indigo/pink/teal brand trio on top of a soft mesh gradient,
/// with translucent glass surfaces painted over the gradient. Status
/// and priority tokens stay unchanged so existing badge widgets keep
/// the same semantic reading.
library;

import 'package:flutter/material.dart';

/// Central color palette. All members are `static const` — this class
/// should never be instantiated.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────
  /// Indigo — primary action color. Used for CTAs, selected states,
  /// and active focus rings.
  static const Color primary = Color(0xFF6366F1);

  /// Slightly deeper indigo for pressed / hovered primary surfaces.
  static const Color primaryDark = Color(0xFF4F46E5);

  /// Pink — secondary accent. Used sparingly for highlights, chips,
  /// and gradient edges.
  static const Color secondary = Color(0xFFEC4899);

  /// Teal — tertiary accent. Used for "info" or "in-flight" hints
  /// and to balance the warm primary/secondary pair.
  static const Color tertiary = Color(0xFF14B8A6);

  /// Error / destructive color.
  static const Color error = Color(0xFFEF4444);

  // ── Gradient (mesh background, light mode) ─────────────────────────
  static const Color gradientLight1 = Color(0xFFE0E7FF); // indigo-100
  static const Color gradientLight2 = Color(0xFFFCE7F3); // pink-100
  static const Color gradientLight3 = Color(0xFFCFFAFE); // cyan-100

  // ── Gradient (mesh background, dark mode) ──────────────────────────
  static const Color gradientDark1 = Color(0xFF1E1B4B); // indigo-950
  static const Color gradientDark2 = Color(0xFF831843); // pink-900
  static const Color gradientDark3 = Color(0xFF164E63); // cyan-900

  // ── Glass surfaces ─────────────────────────────────────────────────
  /// Base fill for frosted cards/sheets on the light background.
  /// Painted over the gradient with a backdrop blur.
  static Color glassSurfaceLight = Colors.white.withValues(alpha: 0.55);

  /// Same idea for dark mode — slate-800 at low alpha.
  static Color glassSurfaceDark =
      const Color(0xFF1E293B).withValues(alpha: 0.55);

  /// Hairline border stroked on top of a glass surface (light mode).
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.30);

  /// Hairline border for dark glass surfaces.
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.15);

  // ── Neutrals ───────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // ── Status tokens (tickets) ────────────────────────────────────────
  static const Color statusOpen = Color(0xFF3B82F6);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF10B981);
  static const Color statusClosed = Color(0xFF6B7280);

  // ── Priority tokens ────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF9CA3AF);
  static const Color priorityMedium = Color(0xFF3B82F6);
  static const Color priorityHigh = Color(0xFFF59E0B);
  static const Color priorityUrgent = Color(0xFFEF4444);

  /// Maps a ticket status string (as stored in the DB check constraint)
  /// to its badge color. Defaults to [neutral400] on unknown values.
  static Color statusColor(String status) {
    switch (status) {
      case 'open':
        return statusOpen;
      case 'in_progress':
        return statusInProgress;
      case 'resolved':
        return statusResolved;
      case 'closed':
        return statusClosed;
      default:
        return neutral400;
    }
  }

  /// Maps a ticket priority string to its badge color.
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'low':
        return priorityLow;
      case 'medium':
        return priorityMedium;
      case 'high':
        return priorityHigh;
      case 'urgent':
        return priorityUrgent;
      default:
        return neutral400;
    }
  }
}
