/// Riverpod `@riverpod` notifier for the app's [ThemeMode], persisted
/// to `shared_preferences`.
///
/// Generated file `theme_provider.g.dart` is produced by
/// `dart run build_runner build`.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_constants.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  @override
  Future<ThemeMode> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(AppConstants.prefThemeMode);
    return _fromString(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, _toString(mode));
  }

  static ThemeMode _fromString(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
