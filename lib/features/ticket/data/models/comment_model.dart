/// Freezed `CommentModel` — wire representation of a row in
/// `ticket_comments`. The datasource embeds the author profile as
/// `user:profiles!user_id(...)` so this model decodes a nested
/// [UserModel] directly.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/comment_entity.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
class CommentModel with _$CommentModel {
  const CommentModel._();

  const factory CommentModel({
    required String id,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @JsonKey(name: 'user_id') required String userId,
    required String message,
    @JsonKey(name: 'attachment_url') String? attachmentUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'user_profile') UserModel? userProfile,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  CommentEntity toEntity() => CommentEntity(
        id: id,
        ticketId: ticketId,
        userId: userId,
        message: message,
        attachmentUrl: attachmentUrl,
        createdAt: createdAt,
        userProfile: userProfile?.toEntity(),
      );
}
