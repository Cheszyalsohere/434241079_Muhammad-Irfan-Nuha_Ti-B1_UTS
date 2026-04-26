/// Aggregate ticket statistics surfaced on the dashboard (FR-008).
///
/// One immutable snapshot, role-scoped by the data layer:
///   • USER     — counts come from tickets where `created_by = self`
///   • HELPDESK — counts from tickets where `assigned_to = self`
///   • ADMIN    — counts across the entire `tickets` table, plus
///                people-counts from `profiles`
///
/// The presentation layer reads the maps directly to render charts
/// without any further grouping work — keep the heavy lifting in the
/// data layer where the SQL/HTTP boundary already exists.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../ticket/domain/entities/ticket_entity.dart';
import 'tickets_per_day_entity.dart';

part 'dashboard_stats_entity.freezed.dart';

@freezed
class DashboardStats with _$DashboardStats {
  const DashboardStats._();

  const factory DashboardStats({
    /// Total tickets in scope (all-time, role-filtered).
    required int total,

    /// Status breakdown — drives both the stat cards and the pie chart.
    required int open,
    required int inProgress,
    required int resolved,
    required int closed,

    /// `category-wire-string -> count`, e.g. `{'hardware': 4, ...}`.
    /// Source of truth for the bar chart; missing keys = zero.
    required Map<String, int> ticketsByCategory,

    /// `priority-wire-string -> count`, e.g. `{'urgent': 1, ...}`.
    required Map<String, int> ticketsByPriority,

    /// Last 7 calendar days of new-ticket counts. Always exactly 7
    /// entries, oldest first, with zeros for inactive days.
    required List<TicketsPerDay> ticketsPerDay,

    /// Average time-to-resolve in hours, computed from
    /// `(updated_at - created_at)` over tickets in `resolved` or
    /// `closed`. Zero when there are no terminal tickets in scope.
    required double avgResolutionHours,

    /// Admin-only people-counters. Defaults to zero for non-admin
    /// payloads so the entity shape stays uniform.
    @Default(0) int totalUsers,
    @Default(0) int totalHelpdesk,
  }) = _DashboardStats;

  /// All-zero stats — useful for placeholder / shimmer scaffolding.
  factory DashboardStats.empty() => DashboardStats(
        total: 0,
        open: 0,
        inProgress: 0,
        resolved: 0,
        closed: 0,
        ticketsByCategory: const <String, int>{},
        ticketsByPriority: const <String, int>{},
        ticketsPerDay: const <TicketsPerDay>[],
        avgResolutionHours: 0,
      );

  /// Indexed by [TicketStatus] so the chart and stat-card builders can
  /// iterate the enum in order without a switch.
  Map<TicketStatus, int> get byStatus => <TicketStatus, int>{
        TicketStatus.open: open,
        TicketStatus.inProgress: inProgress,
        TicketStatus.resolved: resolved,
        TicketStatus.closed: closed,
      };

  /// `true` if every status bucket is zero — drives the empty-state
  /// rendering on the chart.
  bool get isEmpty => total == 0;
}
