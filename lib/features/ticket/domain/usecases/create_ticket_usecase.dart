/// FR-005 — create a new ticket. Trims the title/description and
/// delegates the upload + insert to the repository.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class CreateTicketUseCase {
  const CreateTicketUseCase(this._repo);
  final TicketRepository _repo;

  Future<Either<Failure, TicketEntity>> call({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) {
    return _repo.createTicket(
      title: title.trim(),
      description: description.trim(),
      category: category,
      priority: priority,
      attachmentBytes: attachmentBytes,
      attachmentFileName: attachmentFileName,
    );
  }
}
