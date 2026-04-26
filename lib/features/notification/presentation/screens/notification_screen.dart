/// Notification screen (FR-007).
///
/// Lists realtime-backed notifications for the current user. AppBar
/// has a "Tandai semua dibaca" action that's only enabled when at
/// least one unread item exists. Pull-to-refresh re-runs the
/// controller's one-shot fetch (the realtime subscription itself is
/// always live in the background).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationEntity>> async =
        ref.watch(notificationsControllerProvider);
    final int unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: unread > 0
                ? () => ref
                    .read(notificationsControllerProvider.notifier)
                    .markAllAsRead()
                : null,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Tandai dibaca'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: async.when(
            loading: () =>
                const LoadingIndicator(message: 'Memuat notifikasi...'),
            error: (Object err, _) => _ErrorRetry(
              message: err.toString(),
              onRetry: () =>
                  ref.invalidate(notificationsControllerProvider),
            ),
            data: (List<NotificationEntity> list) {
              if (list.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const <Widget>[
                    SizedBox(height: 80),
                    EmptyState(
                      title: 'Belum ada notifikasi',
                      subtitle:
                          'Pemberitahuan tiket dan komentar akan muncul di sini.',
                      icon: Icons.notifications_off_outlined,
                    ),
                  ],
                );
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                itemBuilder: (BuildContext _, int i) =>
                    NotificationTile(notification: list[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 56),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}
