/// Domain entity for an in-app notification (FR-007).
///
/// Mirrors the `notifications` row. `ticketId` is nullable because
/// the schema allows null (e.g. for system-wide announcements that
/// don't link to a specific ticket).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_entity.freezed.dart';

@freezed
class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    required String id,
    required String userId,
    String? ticketId,
    required String title,
    required String body,
    required bool isRead,
    required DateTime createdAt,
  }) = _NotificationEntity;
}
