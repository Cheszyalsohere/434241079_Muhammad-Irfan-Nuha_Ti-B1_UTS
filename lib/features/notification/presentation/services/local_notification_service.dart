/// Wrapper around `flutter_local_notifications` for showing on-device
/// push notifications when a new realtime row arrives.
///
/// Lifecycle:
///   1. [init] is called once at app start (after Flutter bindings)
///      to register the Android channel and configure click routing.
///   2. [requestPermission] asks for `POST_NOTIFICATIONS` on Android
///      13+ — no-op on older versions.
///   3. [show] fires a notification — payload carries the related
///      ticket id so the click handler can deep-link.
///
/// Click handling:
///   When a notification is tapped, [onTap] (set by the consumer) is
///   invoked with the payload. The consumer typically pushes
///   `/tickets/<id>` via `go_router`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  LocalNotificationService();

  static const String _channelId = 'eticketing_realtime_channel';
  static const String _channelName = 'Notifikasi Tiket';
  static const String _channelDesc =
      'Pemberitahuan untuk pembaruan tiket dan komentar.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the consumer (e.g. the realtime provider) so taps can
  /// deep-link via `go_router`. Optional.
  void Function(String? payload)? onTap;

  bool _initialized = false;

  Future<void> init() async {
    // `flutter_local_notifications` doesn't support web — skip the
    // entire init and let `_initialized` stay false so subsequent
    // `show` calls also short-circuit.
    if (kIsWeb) return;
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        onTap?.call(r.payload);
      },
    );

    // Create the high-importance channel up front.
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// Ask for `POST_NOTIFICATIONS` (Android 13+). Returns `true` if
  /// granted (or not required on older Android versions).
  Future<bool> requestPermission() async {
    // `permission_handler` doesn't support web — browsers prompt the
    // user via the standard Notifications API, but we don't fire
    // local notifications on web at all, so just claim "granted".
    if (kIsWeb) return true;
    try {
      final PermissionStatus s = await Permission.notification.request();
      return s.isGranted || s.isLimited;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification permission request failed: $e');
      }
      return false;
    }
  }

  /// Fire a heads-up notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // No-op on web. Realtime updates still flow into the in-app
    // notification list; we just skip the OS-level toast.
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'eticketing',
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }
}
