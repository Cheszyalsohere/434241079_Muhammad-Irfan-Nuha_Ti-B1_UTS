/// Use case: fetch the latest profile row for a user. Thin wrapper
/// over [ProfileRepository.getProfile].
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Either<Failure, UserEntity>> call(String userId) =>
      _repo.getProfile(userId);
}
