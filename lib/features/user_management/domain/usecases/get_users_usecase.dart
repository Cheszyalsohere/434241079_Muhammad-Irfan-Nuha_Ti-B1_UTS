/// Use case: list all profiles for the admin user-management screen.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/user_management_repository.dart';

class GetUsersUseCase {
  const GetUsersUseCase(this._repo);

  final UserManagementRepository _repo;

  Future<Either<Failure, List<UserEntity>>> call({String? search}) =>
      _repo.getUsers(search: search);
}
