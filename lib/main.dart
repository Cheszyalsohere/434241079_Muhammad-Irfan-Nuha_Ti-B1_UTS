/// Application entrypoint.
///
/// Phase 0: minimal bootstrap so `flutter run` succeeds before feature
/// wiring lands in Phase 1 (Supabase init, Riverpod scope, theme, router).
library;

import 'package:flutter/material.dart';

void main() {
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Ticketing Helpdesk',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Text('E-Ticketing Helpdesk — Phase 0 bootstrap'),
        ),
      ),
    );
  }
}
