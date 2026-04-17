/// Date/time formatting helpers, localized to Indonesian (`id_ID`).
///
/// Call [DateFormatter.init] once in `main.dart` before use, so
/// `intl` initializes locale data.
library;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static const String _locale = 'id_ID';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await initializeDateFormatting(_locale);
    Intl.defaultLocale = _locale;
    _initialized = true;
  }

  /// "18 Apr 2026"
  static String formatDate(DateTime dt) =>
      DateFormat('d MMM y', _locale).format(dt.toLocal());

  /// "18 Apr 2026, 14:30"
  static String formatDateTime(DateTime dt) =>
      DateFormat('d MMM y, HH:mm', _locale).format(dt.toLocal());

  /// Only HH:mm (for same-day timestamps).
  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm', _locale).format(dt.toLocal());

  /// Relative phrasing: "baru saja", "5 menit yang lalu",
  /// "3 jam yang lalu", "kemarin", "5 hari yang lalu", or a full date
  /// for anything older than a week.
  static String relative(DateTime dt, {DateTime? now}) {
    final DateTime n = (now ?? DateTime.now()).toLocal();
    final Duration diff = n.difference(dt.toLocal());

    if (diff.inSeconds < 45) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1) return 'kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    return formatDate(dt);
  }
}
