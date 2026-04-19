/// Abstract `AuthRepository` — contract for authentication operations.
///
/// Implementations live in the data layer. Use cases depend on this
/// interface so the domain remains framework-agnostic.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  /// Authenticate with email + password. Returns the freshly signed-in
  /// user profile on success.
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Create a new account (role is forced to `user` server-side via the
  /// `handle_new_auth_user` trigger).
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  });

  /// Sign out the current session. Idempotent.
  Future<Either<Failure, Unit>> logout();

  /// Send a password-reset (magic link) email.
  Future<Either<Failure, Unit>> resetPassword({required String email});

  /// Resolve the currently authenticated user, or `null` if signed out.
  /// The repository joins `auth.users` with `profiles` to assemble the
  /// full entity.
  Future<Either<Failure, UserEntity?>> currentUser();

  /// Stream of auth state changes — `null` when signed out, populated
  /// `UserEntity` when signed in. Emits on sign-in, sign-out, and token
  /// refresh.
  Stream<UserEntity?> authStateChanges();
}
