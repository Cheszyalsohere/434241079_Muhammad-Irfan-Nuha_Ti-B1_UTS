/// Radio group for Light / Dark / System theme selection, backed by
/// the `@riverpod` ThemeController in `shared/providers/theme_provider.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ThemeMode> state = ref.watch(themeControllerProvider);
    return state.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (Object e, StackTrace _) => Text('Gagal memuat tema: $e'),
      data: (ThemeMode mode) => Card(
        child: Column(
          children: <Widget>[
            _Tile(
              label: 'Terang',
              icon: Icons.light_mode_outlined,
              selected: mode == ThemeMode.light,
              onTap: () => ref
                  .read(themeControllerProvider.notifier)
                  .setMode(ThemeMode.light),
            ),
            const Divider(height: 1),
            _Tile(
              label: 'Gelap',
              icon: Icons.dark_mode_outlined,
              selected: mode == ThemeMode.dark,
              onTap: () => ref
                  .read(themeControllerProvider.notifier)
                  .setMode(ThemeMode.dark),
            ),
            const Divider(height: 1),
            _Tile(
              label: 'Ikuti Sistem',
              icon: Icons.brightness_auto_outlined,
              selected: mode == ThemeMode.system,
              onTap: () => ref
                  .read(themeControllerProvider.notifier)
                  .setMode(ThemeMode.system),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: scheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}
