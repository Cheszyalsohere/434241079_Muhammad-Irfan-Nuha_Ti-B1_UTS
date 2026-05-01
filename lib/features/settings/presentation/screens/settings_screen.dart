/// Settings (`Pengaturan`) screen.
///
/// Sections:
///   • TAMPILAN — Dark Mode toggle (theme_provider) +
///     read-only "Bahasa Indonesia" placeholder tile
///   • NOTIFIKASI — Push Notification switch (notifEnabledProvider)
///   • AKUN — Edit Profil + Ganti Password tiles
///   • TENTANG — Tentang Aplikasi (showAboutAppDialog) + Versi Aplikasi
///
/// Logout intentionally lives elsewhere (AppBar dropdown + Profile
/// screen) so it doesn't compete for attention with the configuration
/// toggles here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/notif_enabled_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/about_app_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // canPop covers the normal in-app push; the fallback
            // catches direct URL navigation on web where there's no
            // prior route to return to.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const <Widget>[
            _SectionHeader('Tampilan'),
            _AppearanceCard(),
            SizedBox(height: 24),
            _SectionHeader('Notifikasi'),
            _NotificationCard(),
            SizedBox(height: 24),
            _SectionHeader('Akun'),
            _AccountCard(),
            SizedBox(height: 24),
            _SectionHeader('Tentang'),
            _AboutCard(),
          ],
        ),
      ),
    );
  }
}

// ── Tampilan ──────────────────────────────────────────────────────────

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode =
        ref.watch(themeControllerProvider).valueOrNull ?? ThemeMode.system;
    final Brightness platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);

    return Card(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            secondary: Icon(
              isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              switch (mode) {
                ThemeMode.light => 'Terang',
                ThemeMode.dark => 'Gelap',
                ThemeMode.system => 'Mengikuti sistem',
              },
            ),
            value: isDark,
            onChanged: (bool v) {
              ref
                  .read(themeControllerProvider.notifier)
                  .setMode(v ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Bahasa'),
            subtitle: Text('Bahasa Indonesia'),
            trailing: Icon(Icons.lock_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Notifikasi ────────────────────────────────────────────────────────

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> async = ref.watch(notifEnabledProvider);
    final bool enabled = async.valueOrNull ?? true;
    final bool ready = !async.isLoading;

    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.notifications_active_outlined),
        title: const Text('Push Notification'),
        subtitle: const Text(
          'Tampilkan notifikasi untuk tiket dan komentar baru',
        ),
        value: ready ? enabled : false,
        onChanged: ready
            ? (bool v) =>
                ref.read(notifEnabledProvider.notifier).setEnabled(v)
            : null,
      ),
    );
  }
}

// ── Akun ──────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.profile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Ganti Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.changePassword),
          ),
        ],
      ),
    );
  }
}

// ── Tentang ───────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutAppDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tag_outlined),
            title: const Text('Versi Aplikasi'),
            trailing: Text(
              AppConstants.appVersion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Misc ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
