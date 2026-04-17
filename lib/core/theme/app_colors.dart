/// Brand + semantic color tokens for the E-Ticketing Helpdesk app.
///
/// All colors referenced by widgets must come from here — never inline
/// hex literals in UI code. Status and priority maps are the single
/// source of truth for chip/badge colors.
library;

import 'package:flutter/material.dart';

/// Central color palette. All members are `static const` — this class
/// should never be instantiated.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

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
