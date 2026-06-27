/// Use case: delete a ticket (BR-002.8). Thin wrapper over
/// [TicketRepository.deleteTicket]. Authorization (owner or admin) is
/// enforced by the DB `tickets_delete` RLS policy.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ticket_repository.dart';

class DeleteTicketUseCase {
  const DeleteTicketUseCase(this._repo);

  final TicketRepository _repo;

  Future<Either<Failure, Unit>> call(String id) => _repo.deleteTicket(id);
}
