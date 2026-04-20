/// Domain entities for the ticket feature.
///
/// Includes the main [TicketEntity], the three enums that drive every
/// chip / filter / dropdown in the UI ([TicketStatus], [TicketPriority],
/// [TicketCategory]), and the lightweight [StatusHistoryEntry] returned
/// alongside ticket detail. All enums expose:
///   • `wire`      — the string value stored in the DB (round-trips)
///   • `fromString` — safe parser that falls back to a default rather
///                    than throwing when a DB row is malformed
///   • `label`     — Indonesian human label (sourced from `AppLabels`)
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/config/app_constants.dart';
import '../../../auth/domain/entities/user_entity.dart';

part 'ticket_entity.freezed.dart';

/// Workflow status — the core of FR-006.
enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  static TicketStatus fromString(String? value) {
    return switch (value) {
      'in_progress' => TicketStatus.inProgress,
      'resolved' => TicketStatus.resolved,
      'closed' => TicketStatus.closed,
      _ => TicketStatus.open,
    };
  }

  String get wire => switch (this) {
        TicketStatus.open => 'open',
        TicketStatus.inProgress => 'in_progress',
        TicketStatus.resolved => 'resolved',
        TicketStatus.closed => 'closed',
      };

  String get label => AppLabels.status[wire] ?? wire;

  bool get isOpen => this == TicketStatus.open;
  bool get isClosed => this == TicketStatus.closed;
  bool get isTerminal =>
      this == TicketStatus.resolved || this == TicketStatus.closed;
}

/// Priority — drives sort order and colored chips.
enum TicketPriority {
  low,
  medium,
  high,
  urgent;

  static TicketPriority fromString(String? value) {
    return switch (value) {
      'low' => TicketPriority.low,
      'high' => TicketPriority.high,
      'urgent' => TicketPriority.urgent,
      _ => TicketPriority.medium,
    };
  }

  String get wire => name;

  String get label => AppLabels.priority[wire] ?? wire;

  /// Numeric weight for sorting (higher = more urgent).
  int get weight => switch (this) {
        TicketPriority.low => 0,
        TicketPriority.medium => 1,
        TicketPriority.high => 2,
        TicketPriority.urgent => 3,
      };
}

/// Category — dropdown values on the create form.
enum TicketCategory {
  hardware,
  software,
  network,
  account,
  other;

  static TicketCategory fromString(String? value) {
    return switch (value) {
      'hardware' => TicketCategory.hardware,
      'software' => TicketCategory.software,
      'network' => TicketCategory.network,
      'account' => TicketCategory.account,
      _ => TicketCategory.other,
    };
  }

  String get wire => name;

  String get label => AppLabels.category[wire] ?? wire;
}

/// A ticket row, with optional eager-loaded author/assignee profiles.
///
/// Both `createdByProfile` and `assignedToProfile` are populated when
/// the repository fetches tickets with the nested `profiles` join;
/// they are null for lean payloads (e.g. when a mutation returns only
/// the base row).
@freezed
class TicketEntity with _$TicketEntity {
  const factory TicketEntity({
    required String id,
    required String ticketNumber,
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    required TicketStatus status,
    String? attachmentUrl,
    required String createdBy,
    String? assignedTo,
    required DateTime createdAt,
    required DateTime updatedAt,
    UserEntity? createdByProfile,
    UserEntity? assignedToProfile,
  }) = _TicketEntity;
}

/// One row from `ticket_status_history`, used to render the timeline.
@freezed
class StatusHistoryEntry with _$StatusHistoryEntry {
  const factory StatusHistoryEntry({
    required String id,
    required String ticketId,
    TicketStatus? oldStatus,
    required TicketStatus newStatus,
    String? changedBy,
    String? notes,
    required DateTime createdAt,
    UserEntity? changedByProfile,
  }) = _StatusHistoryEntry;
}
