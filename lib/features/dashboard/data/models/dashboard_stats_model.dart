/// Data-layer counterpart to [DashboardStats].
///
/// Plain in-memory aggregate — no JSON parsing here. The datasource
/// pulls a thin slice of ticket rows (id/status/category/priority/
/// created_at/updated_at), groups them in Dart, and hands the totals
/// to this model. The model's only job is to hand back a domain
/// entity via [toEntity].
library;

import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/tickets_per_day_entity.dart';

class DashboardStatsModel {
  const DashboardStatsModel({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.closed,
    required this.ticketsByCategory,
    required this.ticketsByPriority,
    required this.ticketsPerDay,
    required this.avgResolutionHours,
    this.totalUsers = 0,
    this.totalHelpdesk = 0,
  });

  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  final int closed;
  final Map<String, int> ticketsByCategory;
  final Map<String, int> ticketsByPriority;
  final List<TicketsPerDay> ticketsPerDay;
  final double avgResolutionHours;
  final int totalUsers;
  final int totalHelpdesk;

  DashboardStats toEntity() => DashboardStats(
        total: total,
        open: open,
        inProgress: inProgress,
        resolved: resolved,
        closed: closed,
        ticketsByCategory: ticketsByCategory,
        ticketsByPriority: ticketsByPriority,
        ticketsPerDay: ticketsPerDay,
        avgResolutionHours: avgResolutionHours,
        totalUsers: totalUsers,
        totalHelpdesk: totalHelpdesk,
      );
}
