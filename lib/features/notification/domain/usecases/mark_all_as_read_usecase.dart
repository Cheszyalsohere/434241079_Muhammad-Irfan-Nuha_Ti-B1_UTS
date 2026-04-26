/// Use case: mark every notification belonging to a user as read.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class MarkAllAsReadUseCase {
  const MarkAllAsReadUseCase(this._repo);

  final NotificationRepository _repo;

  Future<Either<Failure, Unit>> call({required String userId}) =>
      _repo.markAllAsRead(userId);
}
