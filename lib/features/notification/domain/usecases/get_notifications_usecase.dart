/// Use case: fetch the current user's notifications (one-shot).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repo);

  final NotificationRepository _repo;

  Future<Either<Failure, List<NotificationEntity>>> call({
    required String userId,
  }) =>
      _repo.getNotifications(userId);
}
