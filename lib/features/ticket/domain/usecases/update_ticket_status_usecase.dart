/// FR-006 — transition a ticket to a new workflow status. RLS + the
/// update policy already ensure only the owner, helpdesk, or admin
/// can call this; the use case stays thin.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class UpdateTicketStatusUseCase {
  const UpdateTicketStatusUseCase(this._repo);
  final TicketRepository _repo;

  Future<Either<Failure, TicketEntity>> call({
    required String ticketId,
    required TicketStatus newStatus,
  }) {
    return _repo.updateStatus(ticketId: ticketId, newStatus: newStatus);
  }
}
