/// [TicketRepository] implementation. Delegates to
/// [TicketRemoteDataSource] and maps [AppException] subclasses into
/// [Failure]s so upstream layers only deal in domain types.
///
/// Attachment uploads happen here (not the datasource) so the
/// repository orchestrates the "upload then insert" sequence in one
/// place and keeps the datasource CRUD-focused.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_datasource.dart';

class TicketRepositoryImpl implements TicketRepository {
  TicketRepositoryImpl(this._remote);

  final TicketRemoteDataSource _remote;

  // ── Helpers ────────────────────────────────────────────────────────

  Failure _mapException(Object e) {
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) {
      final String m = e.message.toLowerCase();
      if (m.contains('tidak ditemukan')) return NotFoundFailure(e.message);
      if (m.contains('tidak memiliki izin')) {
        return PermissionFailure(e.message);
      }
      return ServerFailure(e.message);
    }
    return const UnknownFailure();
  }

  // ── Reads ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TicketEntity>>> getTickets({
    required int page,
    required int pageSize,
    TicketScope scope = TicketScope.all,
    TicketStatus? status,
    String? search,
  }) async {
    try {
      final List<TicketEntity> list = (await _remote.listTickets(
        page: page,
        pageSize: pageSize,
        scope: scope,
        status: status,
        search: search,
      ))
          .map((m) => m.toEntity())
          .toList(growable: false);
      return Right<Failure, List<TicketEntity>>(list);
    } catch (e) {
      return Left<Failure, List<TicketEntity>>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> getTicketById(String id) async {
    try {
      final TicketEntity t = (await _remote.getTicketById(id)).toEntity();
      return Right<Failure, TicketEntity>(t);
    } catch (e) {
      return Left<Failure, TicketEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getComments(
    String ticketId,
  ) async {
    try {
      final List<CommentEntity> list = (await _remote.listComments(ticketId))
          .map((m) => m.toEntity())
          .toList(growable: false);
      return Right<Failure, List<CommentEntity>>(list);
    } catch (e) {
      return Left<Failure, List<CommentEntity>>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<StatusHistoryEntry>>> getStatusHistory(
    String ticketId,
  ) async {
    try {
      final List<StatusHistoryEntry> list =
          (await _remote.listStatusHistory(ticketId))
              .map((m) => m.toEntity())
              .toList(growable: false);
      return Right<Failure, List<StatusHistoryEntry>>(list);
    } catch (e) {
      return Left<Failure, List<StatusHistoryEntry>>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getHelpdeskStaff() async {
    try {
      final List<Map<String, dynamic>> rows =
          await _remote.listHelpdeskStaff();
      final List<UserEntity> list = rows
          .map((r) => UserModel.fromJson(r).toEntity())
          .toList(growable: false);
      return Right<Failure, List<UserEntity>>(list);
    } catch (e) {
      return Left<Failure, List<UserEntity>>(_mapException(e));
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, TicketEntity>> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    try {
      String? attachmentUrl;
      if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
        attachmentUrl = await _remote.uploadAttachment(
          bytes: attachmentBytes,
          fileName: attachmentFileName ?? 'attachment.jpg',
          subfolder: 'tickets',
        );
      }
      final TicketEntity t = (await _remote.createTicket(
        title: title,
        description: description,
        category: category,
        priority: priority,
        attachmentUrl: attachmentUrl,
      ))
          .toEntity();
      return Right<Failure, TicketEntity>(t);
    } catch (e) {
      return Left<Failure, TicketEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> updateStatus({
    required String ticketId,
    required TicketStatus newStatus,
  }) async {
    try {
      final TicketEntity t = (await _remote.updateTicketStatus(
        ticketId: ticketId,
        newStatus: newStatus,
      ))
          .toEntity();
      return Right<Failure, TicketEntity>(t);
    } catch (e) {
      return Left<Failure, TicketEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> assignTicket({
    required String ticketId,
    required String? assigneeId,
  }) async {
    try {
      final TicketEntity t = (await _remote.assignTicket(
        ticketId: ticketId,
        assigneeId: assigneeId,
      ))
          .toEntity();
      return Right<Failure, TicketEntity>(t);
    } catch (e) {
      return Left<Failure, TicketEntity>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    try {
      String? attachmentUrl;
      if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
        attachmentUrl = await _remote.uploadAttachment(
          bytes: attachmentBytes,
          fileName: attachmentFileName ?? 'attachment.jpg',
          subfolder: 'comments',
        );
      }
      final CommentEntity c = (await _remote.addComment(
        ticketId: ticketId,
        message: message,
        attachmentUrl: attachmentUrl,
      ))
          .toEntity();
      return Right<Failure, CommentEntity>(c);
    } catch (e) {
      return Left<Failure, CommentEntity>(_mapException(e));
    }
  }
}
