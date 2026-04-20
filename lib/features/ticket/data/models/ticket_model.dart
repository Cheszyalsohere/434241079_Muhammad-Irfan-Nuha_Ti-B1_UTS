/// Freezed `TicketModel` — wire representation of a row in the
/// `tickets` table. The datasource queries with embedded joins to the
/// `profiles` table via the two FKs (`created_by`, `assigned_to`);
/// json_serializable deserializes those into nested [UserModel]s.
///
/// Supabase embed aliases used by the datasource:
///   • `created_by_profile:profiles!created_by(...)`
///   • `assigned_to_profile:profiles!assigned_to(...)`
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/ticket_entity.dart';

part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

@freezed
class TicketModel with _$TicketModel {
  const TicketModel._();

  const factory TicketModel({
    required String id,
    @JsonKey(name: 'ticket_number') required String ticketNumber,
    required String title,
    required String description,
    required String category,
    required String priority,
    required String status,
    @JsonKey(name: 'attachment_url') String? attachmentUrl,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'created_by_profile') UserModel? createdByProfile,
    @JsonKey(name: 'assigned_to_profile') UserModel? assignedToProfile,
  }) = _TicketModel;

  factory TicketModel.fromJson(Map<String, dynamic> json) =>
      _$TicketModelFromJson(json);

  TicketEntity toEntity() => TicketEntity(
        id: id,
        ticketNumber: ticketNumber,
        title: title,
        description: description,
        category: TicketCategory.fromString(category),
        priority: TicketPriority.fromString(priority),
        status: TicketStatus.fromString(status),
        attachmentUrl: attachmentUrl,
        createdBy: createdBy,
        assignedTo: assignedTo,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdByProfile: createdByProfile?.toEntity(),
        assignedToProfile: assignedToProfile?.toEntity(),
      );
}
