/// Reusable AppBar overflow menu (PopupMenuButton) with three actions:
/// "Tentang Aplikasi" (about dialog), "Pengaturan" (settings route),
/// and an optional "Keluar" (logout confirmation) entry.
///
/// Drop into any AppBar's `actions:` list — typically as the trailing
/// item after notifications/profile icons.
///
/// `showLogout` defaults to true; the Profile screen passes false
/// because it already exposes a dedicated red logout tile at the
/// bottom of the page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'about_app_dialog.dart';

class AppMenuButton extends ConsumerWidget {
  const AppMenuButton({super.key, this.showLogout = true});

  final bool showLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Menu',
      icon: const Icon(Icons.more_vert),
      onSelected: (_MenuAction action) async {
        switch (action) {
          case _MenuAction.about:
            await showAboutAppDialog(context);
          case _MenuAction.settings:
            if (!context.mounted) return;
            await context.push(AppRoutes.settings);
          case _MenuAction.logout:
            await _confirmAndLogout(context, ref);
        }
      },
      itemBuilder: (BuildContext _) => <PopupMenuEntry<_MenuAction>>[
        const PopupMenuItem<_MenuAction>(
          value: _MenuAction.about,
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Tentang Aplikasi'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem<_MenuAction>(
          value: _MenuAction.settings,
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Pengaturan'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (showLogout) ...<PopupMenuEntry<_MenuAction>>[
          const PopupMenuDivider(),
          PopupMenuItem<_MenuAction>(
            value: _MenuAction.logout,
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                'Keluar',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ],
    );
  }
}

/// Show the same logout confirmation used on the Profile screen, then
/// invoke the existing `AuthController.logout()` use case. The router's
/// auth-aware redirect picks up the cleared session and routes to
/// `/login` automatically.
Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Keluar dari Akun?'),
      content: const Text('Kamu akan keluar dari sesi ini.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) {
    ref.read(authControllerProvider.notifier).clear();
  }
}

enum _MenuAction { about, settings, logout }
