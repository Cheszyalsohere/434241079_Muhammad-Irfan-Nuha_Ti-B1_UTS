/// Splash screen — animated logo, 2s min display, auth check, then
/// redirects to /login or /dashboard via the router.
///
/// Phase 1 placeholder: shows brand mark and waits [AppConstants.splashMinimum]
/// before pushing the initial destination (handled by the router's
/// redirect).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(AppConstants.splashMinimum);
    if (!mounted) return;
    final Session? session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go('/login');
    } else {
      context.go('/dashboard');
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
