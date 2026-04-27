/// [ProfileRepository] implementation. Delegates to
/// [ProfileRemoteDataSource] and maps [AppException]s to [Failure].
///
/// The `uploadAvatar` flow is two-stage (storage upload, then row
/// update) so a partial failure leaves the bucket containing an
/// orphaned object — acceptable because the same path
/// (`avatars/<uid>.<ext>`) is overwritten on the next attempt.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  Failure _mapException(Object e) {
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) {
      final String m = e.message.toLowerCase();
      if (m.contains('tidak ditemukan')) return NotFoundFailure(e.message);
      if (m.contains('tidak memiliki izin')) {
        return PermissionFailure(e.message);
      }
      return ServerFailure(e.message);
    }
    return const UnknownFailure();
  }

  @override
  Future<Either<Failure, UserEntity>> getProfile(String userId) async {
    try {
      final UserEntity u = (await _remote.fetchProfile(userId)).toEntity();
      return Right<Failure, UserEntity>(u);
    } catch (e) {
      return Left<Failure, UserEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required String fullName,
    required String username,
  }) async {
    try {
      final UserEntity u = (await _remote.updateProfile(
        userId: userId,
        fullName: fullName,
        username: username,
      ))
          .toEntity();
      return Right<Failure, UserEntity>(u);
    } catch (e) {
      return Left<Failure, UserEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    try {
      final String url = await _remote.uploadAvatar(
        userId: userId,
        bytes: bytes,
        extension: extension,
      );
      final UserEntity u = (await _remote.updateAvatarUrl(
        userId: userId,
        avatarUrl: url,
      ))
          .toEntity();
      return Right<Failure, UserEntity>(u);
    } catch (e) {
      return Left<Failure, UserEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> clearAvatar(String userId) async {
    try {
      final UserEntity u = (await _remote.updateAvatarUrl(
        userId: userId,
        avatarUrl: null,
      ))
          .toEntity();
      return Right<Failure, UserEntity>(u);
    } catch (e) {
      return Left<Failure, UserEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword(String newPassword) async {
    try {
      await _remote.changePassword(newPassword);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(_mapException(e));
    }
  }
}
