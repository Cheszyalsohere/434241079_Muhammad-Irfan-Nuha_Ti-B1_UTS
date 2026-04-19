/// FR-003 Register use case — role forced to `user` server-side via
/// the `handle_new_auth_user` trigger reading `raw_user_meta_data`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) {
    return _repository.register(
      email: email.trim(),
      password: password,
      username: username.trim(),
      fullName: fullName.trim(),
    );
  }
}
