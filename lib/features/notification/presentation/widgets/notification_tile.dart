/// Single row in the notifications list.
///
/// Visual: glass-y tile (matches the rest of the app's surface
/// language), a primary-tinted dot for unread items, title + body
/// truncated to 2 lines, and a relative timestamp.
///
/// Tapping marks the notification read and — if the row is linked to
/// a ticket — pushes `/tickets/<ticketId>` via `go_router`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';

class NotificationTile extends ConsumerWidget {
  const NotificationTile({super.key, required this.notification});

  final NotificationEntity notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool unread = !notification.isRead;

    return GlassCard(
      onTap: () async {
        if (unread) {
          await ref
              .read(notificationsControllerProvider.notifier)
              .markAsRead(notification.id);
        }
        if (notification.ticketId != null && context.mounted) {
          context.push('/tickets/${notification.ticketId}');
        }
      },
      // Slight tint when unread — the badge is the unread dot below,
      // but a subtle background change adds a second visual cue.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Unread dot — invisible (zero size) when read so layout
          // stays stable.
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: unread
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.relative(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.ticketId != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Buka tiket',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
