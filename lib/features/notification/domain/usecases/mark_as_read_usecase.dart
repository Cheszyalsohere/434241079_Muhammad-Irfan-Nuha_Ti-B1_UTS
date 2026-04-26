/// Use case: mark a single notification as read.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class MarkAsReadUseCase {
  const MarkAsReadUseCase(this._repo);

  final NotificationRepository _repo;

  Future<Either<Failure, Unit>> call({required String notificationId}) =>
      _repo.markAsRead(notificationId);
}
