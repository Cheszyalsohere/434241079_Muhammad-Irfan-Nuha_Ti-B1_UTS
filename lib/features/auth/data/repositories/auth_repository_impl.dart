/// Implementation of [AuthRepository] — delegates to
/// [AuthRemoteDataSource] and maps [AppException]s to [Failure].
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  // ── Helpers ────────────────────────────────────────────────────────

  Failure _mapException(Object e) {
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message);
    if (e is CacheException) return ServerFailure(e.message);
    return const UnknownFailure();
  }

  /// Resolve a fresh [UserEntity] for the given Supabase [user]. Throws
  /// [ServerException] on profile read failure or missing profile row.
  Future<UserEntity> _entityFromSupabaseUser(sb.User user) async {
    final UserModel? profile = await _remote.fetchProfile(
      userId: user.id,
      email: user.email ?? '',
    );
    if (profile == null) {
      throw const ServerException(
        'Profil pengguna tidak ditemukan. Hubungi admin.',
      );
    }
    return profile.toEntity();
  }

  // ── Operations ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final sb.AuthResponse res = await _remote.signIn(
        email: email,
        password: password,
      );
      final sb.User? user = res.user;
      if (user == null) {
        return const Left<Failure, UserEntity>(
          AuthFailure('Login gagal. Coba lagi.'),
        );
      }
      final UserEntity entity = await _entityFromSupabaseUser(user);
      return Right<Failure, UserEntity>(entity);
    } catch (e) {
      return Left<Failure, UserEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final sb.AuthResponse res = await _remote.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );
      final sb.User? user = res.user;
      if (user == null) {
        return const Left<Failure, UserEntity>(
          AuthFailure('Pendaftaran gagal. Coba lagi.'),
        );
      }
      // Profile row is created by `handle_new_auth_user` trigger; fetch
      // it back to assemble the entity.
      final UserEntity entity = await _entityFromSupabaseUser(user);
      return Right<Failure, UserEntity>(entity);
    } catch (e) {
      return Left<Failure, UserEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _remote.signOut();
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({required String email}) async {
    try {
      await _remote.sendPasswordReset(email: email);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> currentUser() async {
    try {
      final sb.Session? session = _remote.currentSession();
      final sb.User? user = session?.user;
      if (user == null) return const Right<Failure, UserEntity?>(null);
      final UserEntity entity = await _entityFromSupabaseUser(user);
      return Right<Failure, UserEntity?>(entity);
    } catch (e) {
      return Left<Failure, UserEntity?>(_mapException(e));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() async* {
    // Yield the current state immediately so subscribers don't need to
    // wait for the next auth event before getting a value.
    final sb.Session? initial = _remote.currentSession();
    if (initial?.user == null) {
      yield null;
    } else {
      try {
        yield await _entityFromSupabaseUser(initial!.user);
      } catch (_) {
        yield null;
      }
    }

    await for (final sb.AuthState state in _remote.onAuthStateChange()) {
      final sb.User? user = state.session?.user;
      if (user == null) {
        yield null;
        continue;
      }
      try {
        yield await _entityFromSupabaseUser(user);
      } catch (_) {
        yield null;
      }
    }
  }
}
