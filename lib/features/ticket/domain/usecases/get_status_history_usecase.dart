/// Use case: load the status-change timeline for one ticket
/// (FR-011 — tracking).
///
/// The repository already exposes `getStatusHistory`; the use case is
/// a thin call-site that the presentation layer's provider depends on
/// — keeps the composition root uniform with the rest of the
/// codebase. One class, one `call()`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class GetStatusHistoryUseCase {
  const GetStatusHistoryUseCase(this._repo);

  final TicketRepository _repo;

  Future<Either<Failure, List<StatusHistoryEntry>>> call(String ticketId) =>
      _repo.getStatusHistory(ticketId);
}
