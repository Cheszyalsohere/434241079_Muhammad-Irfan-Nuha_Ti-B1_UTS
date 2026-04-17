/// Supabase client bootstrapper.
///
/// Reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `.env` (loaded via
/// `flutter_dotenv`) and calls `Supabase.initialize`. Call
/// [SupabaseConfig.init] from `main.dart` after `dotenv.load`.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const String _kUrl = 'SUPABASE_URL';
  static const String _kAnonKey = 'SUPABASE_ANON_KEY';

  /// Idempotent — safe to call multiple times.
  static Future<void> init() async {
    final String url = dotenv.maybeGet(_kUrl) ?? '';
    final String anonKey = dotenv.maybeGet(_kAnonKey) ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase credentials missing. Pastikan .env berisi SUPABASE_URL '
        'dan SUPABASE_ANON_KEY (lihat README section 2 & 3).',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
    );
  }

  /// Convenience accessor.
  static SupabaseClient get client => Supabase.instance.client;
}
