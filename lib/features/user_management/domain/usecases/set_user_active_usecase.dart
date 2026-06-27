/// Use case: activate / deactivate a user account (admin only).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/user_management_repository.dart';

class SetUserActiveUseCase {
  const SetUserActiveUseCase(this._repo);

  final UserManagementRepository _repo;

  Future<Either<Failure, UserEntity>> call({
    required String userId,
    required bool isActive,
  }) =>
      _repo.setActive(userId: userId, isActive: isActive);
}
