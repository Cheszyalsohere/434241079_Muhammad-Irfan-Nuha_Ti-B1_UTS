/// Compile-time constants: table names, storage buckets, page sizes,
/// validation limits, shared preference keys, and user-facing copy.
///
/// Centralizing strings here prevents typos and makes global changes
/// one-line edits.
library;

abstract final class AppConstants {
  // ── Supabase tables & buckets ──────────────────────────────────────
  static const String tblProfiles = 'profiles';
  static const String tblTickets = 'tickets';
  static const String tblTicketComments = 'ticket_comments';
  static const String tblTicketStatusHistory = 'ticket_status_history';
  static const String tblNotifications = 'notifications';
  static const String bucketTicketAttachments = 'ticket-attachments';

  // ── Pagination ─────────────────────────────────────────────────────
  static const int ticketsPageSize = 20;
  static const int notificationsPageSize = 30;

  // ── Validation ─────────────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 120;
  static const int maxDescriptionLength = 2000;
  static const int maxCommentLength = 1000;
  static const int maxAttachmentBytes = 5 * 1024 * 1024; // 5 MB

  // ── SharedPreferences keys ─────────────────────────────────────────
  static const String prefThemeMode = 'pref.theme_mode';
  static const String prefOnboardingSeen = 'pref.onboarding_seen';

  // ── Enumerated values (must match DB check constraints) ────────────
  static const List<String> ticketStatuses = <String>[
    'open',
    'in_progress',
    'resolved',
    'closed',
  ];
  static const List<String> ticketPriorities = <String>[
    'low',
    'medium',
    'high',
    'urgent',
  ];
  static const List<String> ticketCategories = <String>[
    'hardware',
    'software',
    'network',
    'account',
    'other',
  ];
  static const List<String> userRoles = <String>['user', 'helpdesk', 'admin'];

  // ── Durations ──────────────────────────────────────────────────────
  static const Duration splashMinimum = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);
}

/// Human-readable Indonesian labels for status, priority, and category
/// enum values (used for chips, dropdowns, and notifications).
abstract final class AppLabels {
  static const Map<String, String> status = <String, String>{
    'open': 'Terbuka',
    'in_progress': 'Diproses',
    'resolved': 'Selesai',
    'closed': 'Ditutup',
  };

  static const Map<String, String> priority = <String, String>{
    'low': 'Rendah',
    'medium': 'Sedang',
    'high': 'Tinggi',
    'urgent': 'Mendesak',
  };

  static const Map<String, String> category = <String, String>{
    'hardware': 'Hardware',
    'software': 'Software',
    'network': 'Jaringan',
    'account': 'Akun',
    'other': 'Lainnya',
  };

  static const Map<String, String> role = <String, String>{
    'user': 'Pengguna',
    'helpdesk': 'Helpdesk',
    'admin': 'Admin',
  };
}
