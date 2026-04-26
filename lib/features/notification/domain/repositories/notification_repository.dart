/// Abstraction over notification reads + writes + the realtime
/// subscription. Implementation lives in
/// `data/repositories/notification_repository_impl.dart`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract interface class NotificationRepository {
  /// One-shot fetch of the current user's notifications, newest first.
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(
    String userId,
  );

  /// Mark a single notification as read.
  Future<Either<Failure, Unit>> markAsRead(String notificationId);

  /// Mark every notification belonging to [userId] as read.
  Future<Either<Failure, Unit>> markAllAsRead(String userId);

  /// Live subscription. Emits the **full current list** every time any
  /// row for the user changes (insert / update / delete) — Supabase's
  /// `.stream()` API handles the diffing for us.
  ///
  /// The first emission acts as the initial fetch, so consumers don't
  /// need a separate `getNotifications` call when they listen here.
  Stream<List<NotificationEntity>> subscribeToNotifications(String userId);
}
