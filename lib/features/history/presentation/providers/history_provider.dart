/// Riverpod providers for the History feature (FR-010).
///
/// Hierarchy:
///   • [historyRepository] — wraps the existing `ticketRepository` and
///     applies role-aware [TicketScope] filtering.
///   • [getHistoryUseCase] — composition seam for the controller.
///   • [HistoryController] — `AsyncNotifier` that owns the paginated
///     history list, status filter, and debounced search query. Emits
///     a [HistoryState] (tickets + filter snapshot + pagination flag)
///     so the screen can render in one `when()` switch.
///
/// Generated file: `history_provider.g.dart`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';
import '../../../ticket/presentation/providers/ticket_providers.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/get_history_usecase.dart';

part 'history_provider.g.dart';

// ── Composition root ──────────────────────────────────────────────────

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(HistoryRepositoryRef ref) =>
    HistoryRepositoryImpl(ref.watch(ticketRepositoryProvider));

@riverpod
GetHistoryUseCase getHistoryUseCase(GetHistoryUseCaseRef ref) =>
    GetHistoryUseCase(ref.watch(historyRepositoryProvider));

// ── State ─────────────────────────────────────────────────────────────

/// Immutable snapshot consumed by [HistoryScreen]. We bundle filter
/// state alongside the ticket list so the UI can derive everything
/// from a single `AsyncValue<HistoryState>`.
@immutable
class HistoryState {
  const HistoryState({
    required this.tickets,
    required this.status,
    required this.search,
    required this.page,
    required this.hasMore,
  });

  final List<TicketEntity> tickets;
  final TicketStatus? status;
  final String search;
  final int page;
  final bool hasMore;

  HistoryState copyWith({
    List<TicketEntity>? tickets,
    TicketStatus? status,
    bool clearStatus = false,
    String? search,
    int? page,
    bool? hasMore,
  }) {
    return HistoryState(
      tickets: tickets ?? this.tickets,
      status: clearStatus ? null : (status ?? this.status),
      search: search ?? this.search,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  static const HistoryState empty = HistoryState(
    tickets: <TicketEntity>[],
    status: null,
    search: '',
    page: 0,
    hasMore: true,
  );
}

// ── Controller ────────────────────────────────────────────────────────

/// Async controller for the history list. Reads the current user's
/// role from [currentUserProvider] and feeds it to the use case so
/// the same screen renders correctly for every role.
@riverpod
class HistoryController extends _$HistoryController {
  static const int _pageSize = AppConstants.ticketsPageSize;

  TicketStatus? _status;
  String _search = '';

  @override
  Future<HistoryState> build() async {
    // Reset filter state when the user changes (e.g. after logout).
    ref.listen<AsyncValue<UserEntity?>>(currentUserProvider, (_, __) {});
    final HistoryState page0 = await _loadPage(
      page: 0,
      status: _status,
      search: _search,
    );
    return page0;
  }

  UserRole _role() {
    final UserEntity? u = ref.read(currentUserProvider).valueOrNull;
    return u?.role ?? UserRole.user;
  }

  Future<HistoryState> _loadPage({
    required int page,
    TicketStatus? status,
    String? search,
  }) async {
    final Either<Failure, List<TicketEntity>> res =
        await ref.read(getHistoryUseCaseProvider).call(
              role: _role(),
              page: page,
              pageSize: _pageSize,
              status: status,
              search: search,
            );
    return res.fold(
      (Failure f) => throw f,
      (List<TicketEntity> list) => HistoryState(
        tickets: page == 0
            ? list
            : <TicketEntity>[
                ...?state.valueOrNull?.tickets,
                ...list,
              ],
        status: status,
        search: search ?? '',
        page: page,
        hasMore: list.length >= _pageSize,
      ),
    );
  }

  /// Force-reload from page 0 with the currently held filters.
  Future<void> refresh() async {
    state = const AsyncLoading<HistoryState>();
    state = await AsyncValue.guard<HistoryState>(
      () => _loadPage(page: 0, status: _status, search: _search),
    );
  }

  /// Append the next page if not already loading and `hasMore` is true.
  Future<void> loadMore() async {
    final HistoryState? cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || state.isLoading) return;
    final HistoryState next = await _loadPage(
      page: cur.page + 1,
      status: _status,
      search: _search,
    );
    state = AsyncData<HistoryState>(next);
  }

  /// Update the status filter and reload page 0.
  Future<void> setStatusFilter(TicketStatus? value) async {
    if (_status == value) return;
    _status = value;
    await refresh();
  }

  /// Update the (debounced) search query and reload page 0.
  Future<void> setSearch(String value) async {
    final String trimmed = value.trim();
    if (_search == trimmed) return;
    _search = trimmed;
    await refresh();
  }
}
