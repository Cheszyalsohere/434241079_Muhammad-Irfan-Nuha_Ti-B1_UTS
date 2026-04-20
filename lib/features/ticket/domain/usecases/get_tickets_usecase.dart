/// FR-005/FR-006 — paged ticket list with filters.
///
/// Thin pass-through to [TicketRepository.getTickets]; centralized here
/// so the presentation layer can swap in a mock in tests.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class GetTicketsUseCase {
  const GetTicketsUseCase(this._repo);
  final TicketRepository _repo;

  Future<Either<Failure, List<TicketEntity>>> call({
    required int page,
    required int pageSize,
    TicketScope scope = TicketScope.all,
    TicketStatus? status,
    String? search,
  }) {
    return _repo.getTickets(
      page: page,
      pageSize: pageSize,
      scope: scope,
      status: status,
      search: search,
    );
  }
}
