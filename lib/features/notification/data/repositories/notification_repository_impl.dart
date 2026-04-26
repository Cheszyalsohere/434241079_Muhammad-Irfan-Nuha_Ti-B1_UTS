/// [NotificationRepository] implementation. Delegates to the remote
/// datasource and maps [AppException]s into [Failure]s.
///
/// The realtime stream wraps any errors thrown mid-flight in the same
/// failure mapping via `handleError`, so consumers stay in the
/// `Either`/`AsyncValue` world.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  Failure _mapException(Object e) {
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return const UnknownFailure();
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(
    String userId,
  ) async {
    try {
      final List<NotificationEntity> list =
          (await _remote.fetchNotifications(userId))
              .map((m) => m.toEntity())
              .toList(growable: false);
      return Right<Failure, List<NotificationEntity>>(list);
    } catch (e) {
      return Left<Failure, List<NotificationEntity>>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String notificationId) async {
    try {
      await _remote.markAsRead(notificationId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead(String userId) async {
    try {
      await _remote.markAllAsRead(userId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(_mapException(e));
    }
  }

  @override
  Stream<List<NotificationEntity>> subscribeToNotifications(String userId) {
    return _remote.subscribeToNotifications(userId).map(
          (list) =>
              list.map((m) => m.toEntity()).toList(growable: false),
        );
  }
}
