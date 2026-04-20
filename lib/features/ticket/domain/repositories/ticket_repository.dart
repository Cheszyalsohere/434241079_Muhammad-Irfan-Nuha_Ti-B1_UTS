/// Abstract [TicketRepository] — the contract the domain layer depends
/// on and the data layer implements. All methods return
/// `Either<Failure, T>` so the presentation layer can distinguish
/// success / user-facing error paths without try/catch sprawl.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/comment_entity.dart';
import '../entities/ticket_entity.dart';

/// Visibility filter for [TicketRepository.getTickets].
///
/// The RLS policy already gates what the DB will return (a `user`
/// only sees their own rows), but the helpdesk/admin UI surfaces
/// three tabs so staff can jump between queues quickly.
enum TicketScope {
  /// Everything the current user can see (RLS is the only gate).
  all,

  /// Tickets where `created_by = auth.uid()`.
  mine,

  /// Tickets where `assigned_to = auth.uid()`.
  assignedToMe,
}

abstract class TicketRepository {
  /// Paged ticket list (newest updates first) with optional status +
  /// full-text filters. [page] is 0-indexed.
  Future<Either<Failure, List<TicketEntity>>> getTickets({
    required int page,
    required int pageSize,
    TicketScope scope = TicketScope.all,
    TicketStatus? status,
    String? search,
  });

  /// Load one ticket by id (with creator/assignee profiles).
  Future<Either<Failure, TicketEntity>> getTicketById(String id);

  /// All comments on a ticket, oldest first (chronological timeline).
  Future<Either<Failure, List<CommentEntity>>> getComments(String ticketId);

  /// Status change timeline (oldest first).
  Future<Either<Failure, List<StatusHistoryEntry>>> getStatusHistory(
    String ticketId,
  );

  /// Create a new ticket owned by the current user. If attachment
  /// bytes are supplied, they are uploaded to Supabase Storage first
  /// and the resulting public URL is stored on the row.
  Future<Either<Failure, TicketEntity>> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  });

  /// Helpdesk/admin action — move a ticket to [newStatus]. The DB
  /// trigger logs the transition and notifies the owner.
  Future<Either<Failure, TicketEntity>> updateStatus({
    required String ticketId,
    required TicketStatus newStatus,
  });

  /// Helpdesk/admin action — assign a ticket to a staff user.
  /// Pass `null` to unassign.
  Future<Either<Failure, TicketEntity>> assignTicket({
    required String ticketId,
    required String? assigneeId,
  });

  /// Post a comment on a ticket. Optional attachment upload works
  /// the same way as on `createTicket`.
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  });

  /// List helpdesk + admin staff — powers the "assign" dropdown in
  /// the ticket detail screen. Callers rely on the current user's
  /// RLS read access to `profiles`.
  Future<Either<Failure, List<UserEntity>>> getHelpdeskStaff();
}
