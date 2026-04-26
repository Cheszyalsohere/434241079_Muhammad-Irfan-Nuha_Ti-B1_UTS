/// Freezed `NotificationModel` with JSON (de)serialization for
/// `notifications` rows. Wire field names: `user_id`, `ticket_id`,
/// `is_read`, `created_at`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/notification_entity.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'ticket_id') String? ticketId,
    required String title,
    required String body,
    @JsonKey(name: 'is_read') required bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        userId: userId,
        ticketId: ticketId,
        title: title,
        body: body,
        isRead: isRead,
        createdAt: createdAt,
      );
}
