/// Abstract [HistoryRepository] — domain contract for FR-010 (riwayat
/// tiket). Returns role-aware ticket lists sorted by `updated_at`
/// descending.
///
/// Role policy:
///   • `UserRole.user`     → tiket yang dibuat oleh saya
///   • `UserRole.helpdesk` → tiket yang ditugaskan ke saya
///   • `UserRole.admin`    → seluruh tiket
///
/// The repository reuses the existing tickets datasource under the
/// hood — there is no separate `history` table; "history" is just a
/// role-aware view of the live `tickets` table ordered by recency.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';

abstract class HistoryRepository {
  /// Paged history list. [page] is 0-indexed.
  Future<Either<Failure, List<TicketEntity>>> getHistory({
    required UserRole role,
    required int page,
    required int pageSize,
    TicketStatus? status,
    String? search,
  });
}
