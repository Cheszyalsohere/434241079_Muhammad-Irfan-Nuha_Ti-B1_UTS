/// One-tap dark/light theme toggle button for AppBars.
///
/// Reads the current `themeControllerProvider` mode and the device's
/// platform brightness so "system → device dark" still shows the sun
/// icon (tap → switch to explicit light). Tap toggles between
/// [ThemeMode.light] and [ThemeMode.dark]; the "Ikuti Sistem" option
/// remains reachable via the Settings screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode =
        ref.watch(themeControllerProvider).valueOrNull ?? ThemeMode.system;
    final Brightness platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);

    return IconButton(
      tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        ref
            .read(themeControllerProvider.notifier)
            .setMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}
