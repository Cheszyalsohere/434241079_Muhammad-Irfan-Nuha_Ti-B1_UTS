/// Splash screen — animated logo, 2s minimum display, then routes to
/// `/login` or `/dashboard` based on `authStateProvider`.
///
/// We hold for at least [AppConstants.splashMinimum] so the brand mark
/// is visible even on warm starts where the auth state resolves
/// immediately.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(AppConstants.splashMinimum);
    if (!mounted) return;
    // `currentUserProvider` resolves to AsyncData(user) after the first
    // emit from the auth-state stream. Read once, then route.
    final AsyncValue<UserEntity?> userAsync = ref.read(currentUserProvider);
    final UserEntity? user = userAsync.valueOrNull;
    if (user == null) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.support_agent, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'E-Ticketing Helpdesk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }
}
