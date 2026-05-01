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
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeletons/notification_tile_skeleton.dart';
import '../../../../shared/widgets/app_menu_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          const ThemeToggleButton(),
          TextButton.icon(
            onPressed: unread > 0
                ? () => ref
                    .read(notificationsControllerProvider.notifier)
                    .markAllAsRead()
                : null,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Tandai dibaca'),
          ),
          const AppMenuButton(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: async.when(
            loading: () => const NotificationListSkeleton(),
            error: (Object err, _) => ErrorState(
              message: 'Gagal memuat notifikasi.',
              details: err.toString(),
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

