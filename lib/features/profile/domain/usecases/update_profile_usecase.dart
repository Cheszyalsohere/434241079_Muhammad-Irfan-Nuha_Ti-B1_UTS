/// Use case: persist edited profile fields (full name + username).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Either<Failure, UserEntity>> call({
    required String userId,
    required String fullName,
    required String username,
  }) =>
      _repo.updateProfile(
        userId: userId,
        fullName: fullName,
        username: username,
      );
}
