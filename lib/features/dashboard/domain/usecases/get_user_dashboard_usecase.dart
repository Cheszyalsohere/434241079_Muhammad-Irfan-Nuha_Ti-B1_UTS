/// Use case: fetch user-scoped dashboard stats.
///
/// Aggregates only over tickets where `created_by = userId` — what
/// the regular user has personally authored. One class, one `call()`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetUserDashboardUseCase {
  const GetUserDashboardUseCase(this._repo);

  final DashboardRepository _repo;

  Future<Either<Failure, DashboardStats>> call({required String userId}) =>
      _repo.getUserStats(userId);
}
