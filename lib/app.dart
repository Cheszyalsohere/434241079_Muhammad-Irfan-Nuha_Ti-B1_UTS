/// Application root widget — `MaterialApp.router` configured with the
/// Riverpod-backed theme mode and `go_router` instance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/gradient_background.dart';
import 'shared/providers/theme_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ThemeMode> themeAsync = ref.watch(themeControllerProvider);
    final ThemeMode themeMode = themeAsync.valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'E-Ticketing Helpdesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      // Paint the mesh gradient once at the app root so every route
      // (Scaffold is transparent per theme) floats over the same
      // backdrop. `child` is the router's active page.
      builder: (BuildContext context, Widget? child) {
        return GradientBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
