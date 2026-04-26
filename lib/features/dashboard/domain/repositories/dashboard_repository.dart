/// Abstraction over dashboard reads. Implementation lives in
/// `data/repositories/dashboard_repository_impl.dart`.
///
/// One method per role so the call sites stay explicit — there's no
/// "global flag" that forces the reader to mentally trace which role
/// triggers which branch. Use cases each pick the right method.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats_entity.dart';

abstract interface class DashboardRepository {
  /// Aggregates across every ticket in the system and reads people-
  /// counts from `profiles`. Admin-only.
  Future<Either<Failure, DashboardStats>> getAdminStats();

  /// Aggregates over tickets where `assigned_to = userId` — the
  /// helpdesk agent's personal queue.
  Future<Either<Failure, DashboardStats>> getHelpdeskStats(String userId);

  /// Aggregates over tickets where `created_by = userId` — what a
  /// regular user has authored.
  Future<Either<Failure, DashboardStats>> getUserStats(String userId);
}
