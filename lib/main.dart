/// Application entrypoint.
///
/// Bootstrap order:
///   1. Ensure Flutter bindings
///   2. Load `.env` via `flutter_dotenv`
///   3. Initialize Indonesian date formatting
///   4. Initialize Supabase client
///   5. Initialize the local notification channel + request permission
///   6. Run app inside `ProviderScope`
///
/// The realtime notification subscription itself starts lazily — when
/// any widget first watches `notificationsControllerProvider` (e.g.
/// the dashboard's bottom-nav badge after login). Once started, the
/// `keepAlive` flag keeps it subscribed for the rest of the session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/date_formatter.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/notification/presentation/services/local_notification_service.dart';

/// App-wide singleton local notification service. Initialized once
/// before `runApp` and re-exposed to Riverpod via
/// `localNotificationServiceProvider`. We keep a global handle here
/// so `main()` can call `init()`/`requestPermission()` before any
/// widget tree exists.
final LocalNotificationService localNotifications = LocalNotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await DateFormatter.init();
  await SupabaseConfig.init();

  // Set up the Android notification channel up front so the first
  // realtime push has somewhere to land. Permission request is
  // best-effort and does not block boot if the user denies.
  await localNotifications.init();
  await localNotifications.requestPermission();

  runApp(
    ProviderScope(
      overrides: <Override>[
        // Share the pre-initialized service with every consumer so
        // `init()`/`requestPermission()` aren't duplicated.
        localNotificationServiceProvider
            .overrideWithValue(localNotifications),
      ],
      child: const App(),
    ),
  );
}
