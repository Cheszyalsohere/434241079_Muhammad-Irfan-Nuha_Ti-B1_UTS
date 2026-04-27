/// Slim red banner that slides in from the top whenever the device
/// loses network connectivity, and slides out again when it returns.
///
/// Designed to live just below the app's `AppBar` (or at the top of
/// a screen body). Reads [isOnlineProvider] and animates its own
/// height — no manual show/hide calls needed at the call site.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool online = ref.watch(isOnlineProvider);
    final ThemeData theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: online
            ? const SizedBox.shrink(key: ValueKey<String>('online'))
            : Container(
                key: const ValueKey<String>('offline'),
                width: double.infinity,
                color: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: theme.colorScheme.onError,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tidak ada koneksi internet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
