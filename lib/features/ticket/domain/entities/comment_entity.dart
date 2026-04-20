/// Domain `CommentEntity` — one row from `ticket_comments`, with an
/// optional eager-loaded author profile for UI rendering.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/user_entity.dart';

part 'comment_entity.freezed.dart';

@freezed
class CommentEntity with _$CommentEntity {
  const factory CommentEntity({
    required String id,
    required String ticketId,
    required String userId,
    required String message,
    String? attachmentUrl,
    required DateTime createdAt,
    UserEntity? userProfile,
  }) = _CommentEntity;
}
