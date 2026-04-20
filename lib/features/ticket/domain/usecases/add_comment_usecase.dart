/// FR-005 — post a reply on a ticket, optionally with an image
/// attachment that the repository uploads to Supabase Storage.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';
import '../repositories/ticket_repository.dart';

class AddCommentUseCase {
  const AddCommentUseCase(this._repo);
  final TicketRepository _repo;

  Future<Either<Failure, CommentEntity>> call({
    required String ticketId,
    required String message,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) {
    return _repo.addComment(
      ticketId: ticketId,
      message: message.trim(),
      attachmentBytes: attachmentBytes,
      attachmentFileName: attachmentFileName,
    );
  }
}
