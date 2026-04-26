/// [DashboardRepository] implementation — wraps the role-scoped
/// datasource methods with the same exception → failure mapping the
/// rest of the app uses, so the UI's error rendering stays uniform.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  Failure _mapException(Object e) {
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return const UnknownFailure();
  }

  Future<Either<Failure, DashboardStats>> _wrap(
    Future<DashboardStats> Function() fn,
  ) async {
    try {
      final DashboardStats stats = await fn();
      return Right<Failure, DashboardStats>(stats);
    } catch (e) {
      return Left<Failure, DashboardStats>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, DashboardStats>> getAdminStats() =>
      _wrap(() async => (await _remote.fetchAdminStats()).toEntity());

  @override
  Future<Either<Failure, DashboardStats>> getHelpdeskStats(String userId) =>
      _wrap(() async => (await _remote.fetchHelpdeskStats(userId)).toEntity());

  @override
  Future<Either<Failure, DashboardStats>> getUserStats(String userId) =>
      _wrap(() async => (await _remote.fetchUserStats(userId)).toEntity());
}
