/// FR-004 Reset password use case — sends Supabase magic-link email.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call({required String email}) {
    return _repository.resetPassword(email: email.trim());
  }
}
