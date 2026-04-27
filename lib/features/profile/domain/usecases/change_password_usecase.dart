/// Use case: update the signed-in user's password via Supabase Auth.
///
/// Validation (length, confirmation match) happens in the presentation
/// layer before this is called; the use case is a thin pass-through.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Either<Failure, Unit>> call(String newPassword) {
    if (newPassword.length < AppConstants.minPasswordLength) {
      return Future<Either<Failure, Unit>>.value(
        Left<Failure, Unit>(
          ValidationFailure(
            'Kata sandi minimal ${AppConstants.minPasswordLength} karakter.',
          ),
        ),
      );
    }
    return _repo.changePassword(newPassword);
  }
}
