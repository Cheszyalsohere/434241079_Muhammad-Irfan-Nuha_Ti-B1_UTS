/// [UserManagementRepository] implementation — delegates to the remote
/// datasource and maps [AppException]s to [Failure].
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/user_management_remote_datasource.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  UserManagementRepositoryImpl(this._remote);

  final UserManagementRemoteDataSource _remote;

  Failure _map(Object e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) {
      final String m = e.message.toLowerCase();
      if (m.contains('tidak memiliki izin')) return PermissionFailure(e.message);
      if (m.contains('tidak ditemukan')) return NotFoundFailure(e.message);
      return ServerFailure(e.message);
    }
    return const UnknownFailure();
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers({String? search}) async {
    try {
      final List<UserEntity> users = (await _remote.getUsers(search: search))
          .map((m) => m.toEntity())
          .toList();
      return Right<Failure, List<UserEntity>>(users);
    } catch (e) {
      return Left<Failure, List<UserEntity>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      final UserEntity u =
          (await _remote.updateRole(userId: userId, role: role.wire))
              .toEntity();
      return Right<Failure, UserEntity>(u);
    } catch (e) {
      return Left<Failure, UserEntity>(_map(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> setActive({
    required String userId,
    required bool isActive,
  }) async {
    try {
      final UserEntity u =
          (await _remote.setActive(userId: userId, isActive: isActive))
              .toEntity();
      return Right<Failure, UserEntity>(u);
    } catch (e) {
      return Left<Failure, UserEntity>(_map(e));
    }
  }
}
