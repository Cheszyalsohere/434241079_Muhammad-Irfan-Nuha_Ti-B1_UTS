/// Freezed `StatusHistoryModel` — wire representation of a row in
/// `ticket_status_history`. Embeds the changer's profile via
/// `changed_by_profile:profiles!changed_by(...)` when the datasource
/// asks for it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/ticket_entity.dart';

part 'status_history_model.freezed.dart';
part 'status_history_model.g.dart';

@freezed
class StatusHistoryModel with _$StatusHistoryModel {
  const StatusHistoryModel._();

  const factory StatusHistoryModel({
    required String id,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @JsonKey(name: 'old_status') String? oldStatus,
    @JsonKey(name: 'new_status') required String newStatus,
    @JsonKey(name: 'changed_by') String? changedBy,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'changed_by_profile') UserModel? changedByProfile,
  }) = _StatusHistoryModel;

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$StatusHistoryModelFromJson(json);

  StatusHistoryEntry toEntity() => StatusHistoryEntry(
        id: id,
        ticketId: ticketId,
        oldStatus: oldStatus == null ? null : TicketStatus.fromString(oldStatus),
        newStatus: TicketStatus.fromString(newStatus),
        changedBy: changedBy,
        notes: notes,
        createdAt: createdAt,
        changedByProfile: changedByProfile?.toEntity(),
      );
}
