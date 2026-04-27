/// [HistoryRepository] implementation. Delegates to the existing
/// [TicketRepository] — "history" reuses the same `tickets` table,
/// just queried with a role-aware [TicketScope] and sorted by
/// `updated_at` desc (which the ticket datasource already does by
/// default).
///
/// Role → scope mapping:
///   • `UserRole.user`     → [TicketScope.mine]
///   • `UserRole.helpdesk` → [TicketScope.assignedToMe]
///   • `UserRole.admin`    → [TicketScope.all]
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';
import '../../../ticket/domain/repositories/ticket_repository.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._tickets);

  final TicketRepository _tickets;

  TicketScope _scopeFor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return TicketScope.mine;
      case UserRole.helpdesk:
        return TicketScope.assignedToMe;
      case UserRole.admin:
        return TicketScope.all;
    }
  }

  @override
  Future<Either<Failure, List<TicketEntity>>> getHistory({
    required UserRole role,
    required int page,
    required int pageSize,
    TicketStatus? status,
    String? search,
  }) {
    return _tickets.getTickets(
      page: page,
      pageSize: pageSize,
      scope: _scopeFor(role),
      status: status,
      search: search,
    );
  }
}
