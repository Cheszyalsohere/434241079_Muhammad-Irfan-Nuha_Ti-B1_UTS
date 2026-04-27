/// Use case: load the role-aware ticket history list (FR-010).
///
/// Thin wrapper over [HistoryRepository.getHistory] so the presentation
/// layer always depends on a use case rather than a repository — keeps
/// the composition root uniform with the rest of the codebase.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  const GetHistoryUseCase(this._repo);

  final HistoryRepository _repo;

  Future<Either<Failure, List<TicketEntity>>> call({
    required UserRole role,
    required int page,
    required int pageSize,
    TicketStatus? status,
    String? search,
  }) =>
      _repo.getHistory(
        role: role,
        page: page,
        pageSize: pageSize,
        status: status,
        search: search,
      );
}
