/// FR-005 — load a single ticket + its comments + status history in
/// one shot so the detail screen can render everything with a single
/// `AsyncValue`.
library;

import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';
import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

part 'get_ticket_detail_usecase.freezed.dart';

/// Composite payload for the ticket detail screen.
@freezed
class TicketDetail with _$TicketDetail {
  const factory TicketDetail({
    required TicketEntity ticket,
    required List<CommentEntity> comments,
    required List<StatusHistoryEntry> history,
  }) = _TicketDetail;
}

class GetTicketDetailUseCase {
  const GetTicketDetailUseCase(this._repo);
  final TicketRepository _repo;

  Future<Either<Failure, TicketDetail>> call(String ticketId) async {
    final Either<Failure, TicketEntity> ticketRes =
        await _repo.getTicketById(ticketId);
    if (ticketRes.isLeft()) {
      return Left<Failure, TicketDetail>(
        ticketRes.fold((Failure f) => f, (_) => const UnknownFailure()),
      );
    }
    final TicketEntity ticket = ticketRes.getOrElse(
      () => throw StateError('unreachable'),
    );

    final Either<Failure, List<CommentEntity>> commentsRes =
        await _repo.getComments(ticketId);
    if (commentsRes.isLeft()) {
      return Left<Failure, TicketDetail>(
        commentsRes.fold((Failure f) => f, (_) => const UnknownFailure()),
      );
    }

    final Either<Failure, List<StatusHistoryEntry>> historyRes =
        await _repo.getStatusHistory(ticketId);
    if (historyRes.isLeft()) {
      return Left<Failure, TicketDetail>(
        historyRes.fold((Failure f) => f, (_) => const UnknownFailure()),
      );
    }

    return Right<Failure, TicketDetail>(
      TicketDetail(
        ticket: ticket,
        comments: commentsRes.getOrElse(() => const <CommentEntity>[]),
        history: historyRes.getOrElse(() => const <StatusHistoryEntry>[]),
      ),
    );
  }
}
