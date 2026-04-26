/// Remote datasource for the role-aware dashboard.
///
/// Strategy: instead of firing N parallel `count(*)` queries (which the
/// supabase_flutter API surface keeps changing on), pull a thin slice
/// of ticket rows once and aggregate in Dart. For a helpdesk app at
/// university-practicum scale this is dramatically simpler, version-
/// agnostic, and still cheap — we only `select` the columns the chart
/// math needs (id/status/category/priority/created_at/updated_at).
///
/// Three role-scoped methods:
///   • [fetchAdminStats]    — every ticket; also reads `profiles` for
///                            user/helpdesk head-counts
///   • [fetchHelpdeskStats] — tickets where `assigned_to = userId`
///   • [fetchUserStats]     — tickets where `created_by = userId`
///
/// All three return the same [DashboardStatsModel] shape, so the
/// presentation layer doesn't fork on role for rendering primitives.
library;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';
import '../../domain/entities/tickets_per_day_entity.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  /// Columns we need to compute every aggregate the dashboard renders.
  /// Kept narrow so the over-the-wire payload is tiny even when the
  /// `tickets` table grows past the seed dataset.
  static const String _ticketSlice =
      'id, status, category, priority, created_at, updated_at';

  // ── Public API ────────────────────────────────────────────────────────

  Future<DashboardStatsModel> fetchAdminStats() async {
    try {
      final List<Map<String, dynamic>> rows = await _fetchTicketSlice();
      // People-counts only matter for admin — fire in parallel with the
      // ticket aggregation so we don't pay two round-trips serially.
      final List<int> counts = await Future.wait<int>(<Future<int>>[
        _profilesCount('user'),
        _profilesCount('helpdesk'),
      ]);
      return _aggregate(
        rows,
        totalUsers: counts[0],
        totalHelpdesk: counts[1],
      );
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memuat statistik dashboard.', cause: e);
    }
  }

  Future<DashboardStatsModel> fetchHelpdeskStats(String userId) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _fetchTicketSlice(filterColumn: 'assigned_to', uid: userId);
      return _aggregate(rows);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memuat statistik dashboard.', cause: e);
    }
  }

  Future<DashboardStatsModel> fetchUserStats(String userId) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _fetchTicketSlice(filterColumn: 'created_by', uid: userId);
      return _aggregate(rows);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memuat statistik dashboard.', cause: e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Pulls the column slice with an optional `created_by`/`assigned_to`
  /// scope. Chained `dynamic` because PostgREST builders erase type on
  /// each filter — the terminal `await` returns `List<Map<...>>`.
  Future<List<Map<String, dynamic>>> _fetchTicketSlice({
    String? filterColumn,
    String? uid,
  }) async {
    dynamic q = _client.from(AppConstants.tblTickets).select(_ticketSlice);
    if (filterColumn != null && uid != null) {
      q = q.eq(filterColumn, uid);
    }
    final List<dynamic> rows = (await q) as List<dynamic>;
    return rows
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<int> _profilesCount(String role) async {
    dynamic q =
        _client.from(AppConstants.tblProfiles).select('id').eq('role', role);
    final List<dynamic> rows = (await q) as List<dynamic>;
    return rows.length;
  }

  /// Pure Dart aggregation — fold ticket rows into the model. Stays in
  /// one place so all three role flavours produce identical shapes.
  DashboardStatsModel _aggregate(
    List<Map<String, dynamic>> rows, {
    int totalUsers = 0,
    int totalHelpdesk = 0,
  }) {
    int open = 0, inProgress = 0, resolved = 0, closed = 0;
    final Map<String, int> byCategory = <String, int>{
      for (final String c in AppConstants.ticketCategories) c: 0,
    };
    final Map<String, int> byPriority = <String, int>{
      for (final String p in AppConstants.ticketPriorities) p: 0,
    };

    // For the 7-day trend: map normalized date -> count. The presenter
    // gets a contiguous list (oldest -> newest) so the line chart can
    // index by position.
    final DateTime today = _normalizeDate(DateTime.now());
    final DateTime sevenDaysAgo = today.subtract(const Duration(days: 6));
    final Map<DateTime, int> perDayMap = <DateTime, int>{
      for (int i = 0; i < 7; i++)
        sevenDaysAgo.add(Duration(days: i)): 0,
    };

    // For avg-resolution: accumulate (updated_at - created_at) for every
    // ticket whose status is terminal. We treat `updated_at` as a proxy
    // for resolution time — the schema's `updated_at` trigger fires on
    // any row mutation, so for a status flip into `resolved`/`closed`
    // it's a reasonable approximation.
    int resolutionSamples = 0;
    double resolutionHoursTotal = 0;

    for (final Map<String, dynamic> row in rows) {
      final String statusWire = (row['status'] as String?) ?? 'open';
      final String categoryWire = (row['category'] as String?) ?? 'other';
      final String priorityWire = (row['priority'] as String?) ?? 'medium';

      switch (TicketStatus.fromString(statusWire)) {
        case TicketStatus.open:
          open++;
        case TicketStatus.inProgress:
          inProgress++;
        case TicketStatus.resolved:
          resolved++;
        case TicketStatus.closed:
          closed++;
      }

      byCategory.update(
        categoryWire,
        (int v) => v + 1,
        ifAbsent: () => 1,
      );
      byPriority.update(
        priorityWire,
        (int v) => v + 1,
        ifAbsent: () => 1,
      );

      final DateTime? createdAt =
          DateTime.tryParse((row['created_at'] as String?) ?? '');
      if (createdAt != null) {
        final DateTime day = _normalizeDate(createdAt.toLocal());
        if (perDayMap.containsKey(day)) {
          perDayMap[day] = (perDayMap[day] ?? 0) + 1;
        }
      }

      if (statusWire == 'resolved' || statusWire == 'closed') {
        final DateTime? updatedAt =
            DateTime.tryParse((row['updated_at'] as String?) ?? '');
        if (createdAt != null && updatedAt != null) {
          final double hours =
              updatedAt.difference(createdAt).inMinutes / 60.0;
          if (hours >= 0) {
            resolutionHoursTotal += hours;
            resolutionSamples++;
          }
        }
      }
    }

    final List<TicketsPerDay> perDay = perDayMap.entries
        .map(
          (MapEntry<DateTime, int> e) =>
              TicketsPerDay(date: e.key, count: e.value),
        )
        .toList(growable: false)
      ..sort((TicketsPerDay a, TicketsPerDay b) => a.date.compareTo(b.date));

    final double avgHours = resolutionSamples == 0
        ? 0
        : resolutionHoursTotal / resolutionSamples;

    return DashboardStatsModel(
      total: rows.length,
      open: open,
      inProgress: inProgress,
      resolved: resolved,
      closed: closed,
      ticketsByCategory: byCategory,
      ticketsByPriority: byPriority,
      ticketsPerDay: perDay,
      avgResolutionHours: avgHours,
      totalUsers: totalUsers,
      totalHelpdesk: totalHelpdesk,
    );
  }

  /// Strip time-of-day so `created_at` from the same calendar day
  /// collapses into a single bucket.
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);
}
