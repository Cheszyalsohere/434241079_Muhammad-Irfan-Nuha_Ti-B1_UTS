/// Riverpod `@riverpod` notifier for the user's "show push
/// notifications" preference, persisted to `shared_preferences`.
///
/// Default: enabled (true). Toggling off makes
/// `NotificationsController` skip `LocalNotificationService.show()` so
/// realtime rows still flow into the in-app list, but no OS-level
/// heads-up fires.
///
/// Generated file `notif_enabled_provider.g.dart` is produced by
/// `dart run build_runner build`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_constants.dart';

part 'notif_enabled_provider.g.dart';

@Riverpod(keepAlive: true)
class NotifEnabled extends _$NotifEnabled {
  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefPushNotifications) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncData<bool>(value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefPushNotifications, value);
  }
}
