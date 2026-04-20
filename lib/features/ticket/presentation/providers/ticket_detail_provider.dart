/// Ticket detail + mutation controller. The family key is the
/// ticket id so every open detail screen gets its own cache bucket
/// and mutation tracker.
///
/// `build` resolves the composite [TicketDetail] (ticket + comments +
/// status history). Mutations (add comment, change status, assign)
/// re-run `build` on success so every change rehydrates the full
/// bundle — no clever patching required, and the UI is always
/// consistent with what the DB actually wrote.
///
/// Generated file: `ticket_detail_provider.g.dart`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/usecases/get_ticket_detail_usecase.dart';
import 'ticket_providers.dart';

part 'ticket_detail_provider.g.dart';

/// Composite ticket detail (+ comments + history).
@riverpod
class TicketDetailController extends _$TicketDetailController {
  @override
  Future<TicketDetail> build(String ticketId) async {
    final Either<Failure, TicketDetail> res =
        await ref.read(getTicketDetailUseCaseProvider).call(ticketId);
    return res.fold(
      (Failure f) => throw f,
      (TicketDetail d) => d,
    );
  }

  /// Force a full reload from the network (used by pull-to-refresh
  /// and after any mutation).
  Future<void> refresh() async {
    state = const AsyncLoading<TicketDetail>();
    state = await AsyncValue.guard<TicketDetail>(() async {
      final Either<Failure, TicketDetail> res =
          await ref.read(getTicketDetailUseCaseProvider).call(ticketId);
      return res.fold(
        (Failure f) => throw f,
        (TicketDetail d) => d,
      );
    });
  }

  Future<bool> addComment({
    required String message,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    final Either<Failure, CommentEntity> res =
        await ref.read(addCommentUseCaseProvider).call(
              ticketId: ticketId,
              message: message,
              attachmentBytes: attachmentBytes,
              attachmentFileName: attachmentFileName,
            );
    return res.fold(
      (Failure f) {
        state = AsyncError<TicketDetail>(f, StackTrace.current);
        return false;
      },
      (_) async {
        await refresh();
        return true;
      },
    );
  }

  Future<bool> updateStatus(TicketStatus newStatus) async {
    final Either<Failure, TicketEntity> res =
        await ref.read(updateTicketStatusUseCaseProvider).call(
              ticketId: ticketId,
              newStatus: newStatus,
            );
    return res.fold(
      (Failure f) {
        state = AsyncError<TicketDetail>(f, StackTrace.current);
        return false;
      },
      (_) async {
        await refresh();
        return true;
      },
    );
  }

  Future<bool> assign(String? assigneeId) async {
    final Either<Failure, TicketEntity> res =
        await ref.read(assignTicketUseCaseProvider).call(
              ticketId: ticketId,
              assigneeId: assigneeId,
            );
    return res.fold(
      (Failure f) {
        state = AsyncError<TicketDetail>(f, StackTrace.current);
        return false;
      },
      (_) async {
        await refresh();
        return true;
      },
    );
  }
}

/// Helpdesk staff list (cached) for the "Tugaskan" dropdown.
@riverpod
Future<List<UserEntity>> helpdeskStaff(HelpdeskStaffRef ref) async {
  final Either<Failure, List<UserEntity>> res =
      await ref.watch(ticketRepositoryProvider).getHelpdeskStaff();
  return res.fold(
    (Failure f) => throw f,
    (List<UserEntity> list) {
      if (kDebugMode) {
        // Sorted by name already by the datasource; no-op comment to
        // keep the fold branches symmetric.
      }
      return list;
    },
  );
}
