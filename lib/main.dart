/// Application entrypoint.
///
/// Bootstrap order:
///   1. Ensure Flutter bindings
///   2. Load `.env` via `flutter_dotenv`
///   3. Initialize Indonesian date formatting
///   4. Initialize Supabase client
///   5. Run app inside `ProviderScope`
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/date_formatter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await DateFormatter.init();
  await SupabaseConfig.init();

  runApp(const ProviderScope(child: App()));
}
