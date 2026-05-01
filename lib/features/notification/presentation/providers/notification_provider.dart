/// Riverpod providers for the notification feature.
///
/// Hierarchy:
///   • [notificationRemoteDataSource] / [notificationRepository] — DI
///     seams (keepAlive — they outlive any single screen)
///   • Use case providers — one per use case
///   • [localNotificationService] — singleton wrapper around
///     `flutter_local_notifications`, init'd at app start
///   • [NotificationsController] — async list controller. `build()`
///     subscribes to the realtime stream and feeds local push
///     notifications when a new unread row appears.
///   • [unreadCount] — derived count for the badge in the bottom nav
///
/// Generated file: `notification_provider.g.dart`.
library;

import 'package:dartz/dartz.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/notif_enabled_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/subscribe_notifications_usecase.dart';
import '../services/local_notification_service.dart';

part 'notification_provider.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
NotificationRemoteDataSource notificationRemoteDataSource(
  NotificationRemoteDataSourceRef ref,
) =>
    NotificationRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(
  NotificationRepositoryRef ref,
) =>
    NotificationRepositoryImpl(
      ref.watch(notificationRemoteDataSourceProvider),
    );

// ── Use cases ─────────────────────────────────────────────────────────

@riverpod
GetNotificationsUseCase getNotificationsUseCase(
  GetNotificationsUseCaseRef ref,
) =>
    GetNotificationsUseCase(ref.watch(notificationRepositoryProvider));

@riverpod
MarkAsReadUseCase markAsReadUseCase(MarkAsReadUseCaseRef ref) =>
    MarkAsReadUseCase(ref.watch(notificationRepositoryProvider));

@riverpod
MarkAllAsReadUseCase markAllAsReadUseCase(MarkAllAsReadUseCaseRef ref) =>
    MarkAllAsReadUseCase(ref.watch(notificationRepositoryProvider));

@riverpod
SubscribeNotificationsUseCase subscribeNotificationsUseCase(
  SubscribeNotificationsUseCaseRef ref,
) =>
    SubscribeNotificationsUseCase(ref.watch(notificationRepositoryProvider));

// ── Local notification service ────────────────────────────────────────

/// Single instance of the on-device notification wrapper. Initialized
/// in `main.dart` before `runApp`.
@Riverpod(keepAlive: true)
LocalNotificationService localNotificationService(
  LocalNotificationServiceRef ref,
) =>
    LocalNotificationService();

// ── Controller ────────────────────────────────────────────────────────

/// Async list controller backed by the realtime stream.
///
/// `build()` does two things:
///   1. Performs a one-shot fetch via the use case for a snappy first
///      frame (so the list isn't empty for the brief window before
///      the stream's initial emission lands).
///   2. Subscribes to the realtime stream. Every emission overwrites
///      the controller's state and — for any *new* row that's also
///      unread — fires a local push notification.
///
/// The "seen ids" set is what keeps the local push from re-firing for
/// rows that were just marked read or that were present in the
/// initial load.
@Riverpod(keepAlive: true)
class NotificationsController extends _$NotificationsController {
  @override
  Future<List<NotificationEntity>> build() async {
    final UserEntity? user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const <NotificationEntity>[];
    }

    // 1. Initial fetch.
    final Either<Failure, List<NotificationEntity>> initial =
        await ref.read(getNotificationsUseCaseProvider).call(userId: user.id);
    final List<NotificationEntity> initialList =
        initial.fold((Failure f) => throw f, (List<NotificationEntity> l) => l);

    // 2. Subscribe — realtime overwrites state on every emit.
    final Set<String> seenIds = <String>{
      for (final NotificationEntity n in initialList) n.id,
    };
    int pushId = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

    final sub = ref
        .read(subscribeNotificationsUseCaseProvider)
        .call(userId: user.id)
        .listen(
      (List<NotificationEntity> list) {
        // Detect newly arrived rows and push for any that are unread.
        // Skip the OS-level toast when the user has turned push
        // notifications off in Settings — the in-app list still
        // updates from `state = AsyncData(...)` below.
        final bool pushEnabled =
            ref.read(notifEnabledProvider).valueOrNull ?? true;
        for (final NotificationEntity n in list) {
          if (!seenIds.contains(n.id)) {
            seenIds.add(n.id);
            if (!n.isRead && pushEnabled) {
              ref.read(localNotificationServiceProvider).show(
                    id: pushId++,
                    title: n.title,
                    body: n.body,
                    payload: n.ticketId,
                  );
            }
          }
        }
        state = AsyncData<List<NotificationEntity>>(list);
      },
      onError: (Object e, StackTrace st) {
        state = AsyncError<List<NotificationEntity>>(e, st);
      },
    );
    ref.onDispose(sub.cancel);

    return initialList;
  }

  /// Pull-to-refresh — ignores the stream and re-runs the one-shot
  /// fetch. The stream itself stays subscribed.
  Future<void> refresh() async {
    final UserEntity? user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    state = const AsyncLoading<List<NotificationEntity>>();
    state = await AsyncValue.guard<List<NotificationEntity>>(() async {
      final Either<Failure, List<NotificationEntity>> res = await ref
          .read(getNotificationsUseCaseProvider)
          .call(userId: user.id);
      return res.fold((Failure f) => throw f, (List<NotificationEntity> l) => l);
    });
  }

  /// Mark a single notification as read. The realtime stream will
  /// echo the update back into [state] — we don't need to patch
  /// optimistically.
  Future<void> markAsRead(String id) async {
    await ref
        .read(markAsReadUseCaseProvider)
        .call(notificationId: id);
  }

  /// Mark every notification as read.
  Future<void> markAllAsRead() async {
    final UserEntity? user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    await ref.read(markAllAsReadUseCaseProvider).call(userId: user.id);
  }
}

// ── Derived ───────────────────────────────────────────────────────────

/// Unread badge count. Reads from the controller; falls back to zero
/// while loading or on error so the badge never lies upward.
@riverpod
int unreadCount(UnreadCountRef ref) {
  final AsyncValue<List<NotificationEntity>> async =
      ref.watch(notificationsControllerProvider);
  return async.maybeWhen(
    data: (List<NotificationEntity> list) =>
        list.where((NotificationEntity n) => !n.isRead).length,
    orElse: () => 0,
  );
}

// ── Tap routing helper ────────────────────────────────────────────────

/// Wires up `onTap` on the local-notification service so a heads-up
/// tap navigates to the related ticket. Call once after the router
/// is built.
///
/// Pure function — no provider — because GoRouter is owned by [App]
/// and we just need a one-time hookup at boot.
void wireNotificationTaps(
  LocalNotificationService service,
  GoRouter router,
) {
  service.onTap = (String? payload) {
    if (payload == null || payload.isEmpty) {
      router.go(AppRoutes.notifications);
      return;
    }
    router.push('/tickets/$payload');
  };
}
