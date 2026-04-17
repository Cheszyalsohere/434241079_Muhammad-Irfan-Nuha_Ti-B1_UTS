/// Profile screen — Phase 1 shell with theme toggle wired in; full
/// avatar + role management arrives in Phase 7.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/theme_toggle.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _SectionHeader('Tampilan'),
          SizedBox(height: 8),
          ThemeToggle(),
          SizedBox(height: 24),
          _SectionHeader('Akun'),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Akun (TODO Phase 7)'),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Keluar (TODO Phase 2)'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
