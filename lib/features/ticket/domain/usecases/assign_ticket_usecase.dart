/// FR-006 — assign a ticket to a helpdesk user. Pass a null
/// `assigneeId` to unassign.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class AssignTicketUseCase {
  const AssignTicketUseCase(this._repo);
  final TicketRepository _repo;

  Future<Either<Failure, TicketEntity>> call({
    required String ticketId,
    required String? assigneeId,
  }) {
    return _repo.assignTicket(ticketId: ticketId, assigneeId: assigneeId);
  }
}
