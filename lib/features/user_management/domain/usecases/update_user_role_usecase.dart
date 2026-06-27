/// Use case: change a user's role (admin only).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/user_management_repository.dart';

class UpdateUserRoleUseCase {
  const UpdateUserRoleUseCase(this._repo);

  final UserManagementRepository _repo;

  Future<Either<Failure, UserEntity>> call({
    required String userId,
    required UserRole role,
  }) =>
      _repo.updateRole(userId: userId, role: role);
}
