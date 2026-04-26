/// Use case: fetch helpdesk-scoped dashboard stats.
///
/// Aggregates only over tickets where `assigned_to = userId` — i.e.
/// the helpdesk agent's personal queue. One class, one `call()`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetHelpdeskDashboardUseCase {
  const GetHelpdeskDashboardUseCase(this._repo);

  final DashboardRepository _repo;

  Future<Either<Failure, DashboardStats>> call({required String userId}) =>
      _repo.getHelpdeskStats(userId);
}
