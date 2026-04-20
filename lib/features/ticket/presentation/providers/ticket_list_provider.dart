/// Ticket list state — a `Notifier` that owns the filter parameters
/// (scope/status/search) plus the paged result set and an "has more"
/// flag. The UI binds a `TabController` + search field to this and
/// calls `loadMore`/`refresh` as the user scrolls.
///
/// Generated file: `ticket_list_provider.g.dart`.
library;

import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import 'ticket_providers.dart';

part 'ticket_list_provider.freezed.dart';
part 'ticket_list_provider.g.dart';

/// Immutable snapshot of the list screen.
@freezed
class TicketListState with _$TicketListState {
  const factory TicketListState({
    required TicketScope scope,
    TicketStatus? status,
    @Default('') String search,
    @Default(<TicketEntity>[]) List<TicketEntity> tickets,
    @Default(0) int page,
    @Default(true) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,
    Failure? error,
  }) = _TicketListState;
}

/// Controller for the ticket list. The `family` arg is the initial
/// [TicketScope] so helpdesk/admin tabs can each keep independent
/// pagination state.
@riverpod
class TicketListController extends _$TicketListController {
  static const int _pageSize = AppConstants.ticketsPageSize;

  @override
  Future<TicketListState> build(TicketScope initialScope) async {
    final TicketListState seed = TicketListState(scope: initialScope);
    final TicketListState loaded = await _fetchFirstPage(seed);
    return loaded;
  }

  Future<TicketListState> _fetchFirstPage(TicketListState s) async {
    final Either<Failure, List<TicketEntity>> res =
        await ref.read(getTicketsUseCaseProvider).call(
              page: 0,
              pageSize: _pageSize,
              scope: s.scope,
              status: s.status,
              search: s.search.isEmpty ? null : s.search,
            );
    return res.fold(
      (Failure f) => s.copyWith(error: f, hasMore: false),
      (List<TicketEntity> list) => s.copyWith(
        tickets: list,
        page: 0,
        hasMore: list.length >= _pageSize,
        error: null,
      ),
    );
  }

  /// Re-run the first page with the current filters (pull-to-refresh).
  Future<void> refresh() async {
    final TicketListState current = state.value ??
        TicketListState(scope: initialScope);
    state = AsyncData<TicketListState>(current.copyWith(refreshing: true));
    final TicketListState next = await _fetchFirstPage(current);
    state = AsyncData<TicketListState>(next.copyWith(refreshing: false));
  }

  /// Fetch the next page and append. Silently no-ops when [hasMore] is
  /// false or a load is already in flight.
  Future<void> loadMore() async {
    final TicketListState? current = state.value;
    if (current == null) return;
    if (!current.hasMore || current.loadingMore) return;

    state = AsyncData<TicketListState>(current.copyWith(loadingMore: true));
    final int nextPage = current.page + 1;
    final Either<Failure, List<TicketEntity>> res =
        await ref.read(getTicketsUseCaseProvider).call(
              page: nextPage,
              pageSize: _pageSize,
              scope: current.scope,
              status: current.status,
              search: current.search.isEmpty ? null : current.search,
            );
    state = AsyncData<TicketListState>(
      res.fold(
        (Failure f) => current.copyWith(loadingMore: false, error: f),
        (List<TicketEntity> list) => current.copyWith(
          tickets: <TicketEntity>[...current.tickets, ...list],
          page: nextPage,
          hasMore: list.length >= _pageSize,
          loadingMore: false,
          error: null,
        ),
      ),
    );
  }

  /// Apply a new status filter (null = all statuses) and re-fetch.
  Future<void> setStatusFilter(TicketStatus? status) async {
    final TicketListState current = state.value ??
        TicketListState(scope: initialScope);
    if (current.status == status) return;
    state = AsyncData<TicketListState>(
      current.copyWith(status: status, tickets: const <TicketEntity>[]),
    );
    final TicketListState next =
        await _fetchFirstPage(state.value ?? current);
    state = AsyncData<TicketListState>(next);
  }

  /// Apply a new search query and re-fetch. Callers should debounce
  /// this from the text field's `onChanged`.
  Future<void> setSearch(String query) async {
    final TicketListState current = state.value ??
        TicketListState(scope: initialScope);
    if (current.search == query) return;
    state = AsyncData<TicketListState>(
      current.copyWith(search: query, tickets: const <TicketEntity>[]),
    );
    final TicketListState next =
        await _fetchFirstPage(state.value ?? current);
    state = AsyncData<TicketListState>(next);
  }
}
