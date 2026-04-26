/// Use case: fetch admin-scoped dashboard stats.
///
/// Wraps [DashboardRepository.getAdminStats]. One class, one `call()`
/// — per the project's quality gate.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetAdminDashboardUseCase {
  const GetAdminDashboardUseCase(this._repo);

  final DashboardRepository _repo;

  Future<Either<Failure, DashboardStats>> call() => _repo.getAdminStats();
}
