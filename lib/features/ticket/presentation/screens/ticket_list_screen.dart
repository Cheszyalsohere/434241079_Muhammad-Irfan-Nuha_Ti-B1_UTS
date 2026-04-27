/// Ticket list screen — FR-005/FR-006.
///
/// Layout:
///   • `AppBar` with a search icon that expands inline
///   • `TabBar` — for regular users: just a "Tiket Saya" tab; for
///     helpdesk/admin: three tabs (Semua / Saya / Ditugaskan)
///   • Filter chips row for status
///   • Paginated `ListView` with pull-to-refresh + infinite scroll
///   • FAB → `/tickets/create`
///
/// Each tab owns its own `TicketListController` family instance so
/// filter/pagination state doesn't bleed across scopes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeletons/ticket_card_skeleton.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../providers/ticket_list_provider.dart';
import '../widgets/ticket_card.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserEntity?> userAsync = ref.watch(currentUserProvider);
    final UserEntity? user = userAsync.valueOrNull;
    final bool staff = user?.role.canManageAllTickets ?? false;

    final List<TicketScope> scopes = staff
        ? const <TicketScope>[
            TicketScope.all,
            TicketScope.mine,
            TicketScope.assignedToMe,
          ]
        : const <TicketScope>[TicketScope.mine];

    final List<Tab> tabs = staff
        ? const <Tab>[
            Tab(text: 'Semua'),
            Tab(text: 'Dibuat Saya'),
            Tab(text: 'Ditugaskan'),
          ]
        : const <Tab>[Tab(text: 'Tiket Saya')];

    return DefaultTabController(
      length: scopes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tiket'),
          bottom: tabs.length > 1
              ? TabBar(tabs: tabs)
              : const PreferredSize(
                  preferredSize: Size.zero,
                  child: SizedBox.shrink(),
                ),
        ),
        body: TabBarView(
          children: <Widget>[
            for (final TicketScope scope in scopes)
              _ScopeTab(scope: scope, key: ValueKey<TicketScope>(scope)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.ticketCreate),
          icon: const Icon(Icons.add),
          label: const Text('Tiket Baru'),
        ),
      ),
    );
  }
}

class _ScopeTab extends ConsumerStatefulWidget {
  const _ScopeTab({required this.scope, super.key});
  final TicketScope scope;

  @override
  ConsumerState<_ScopeTab> createState() => _ScopeTabState();
}

class _ScopeTabState extends ConsumerState<_ScopeTab> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final double offset = _scroll.position.pixels;
    final double max = _scroll.position.maxScrollExtent;
    if (max - offset < 240) {
      ref
          .read(ticketListControllerProvider(widget.scope).notifier)
          .loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref
          .read(ticketListControllerProvider(widget.scope).notifier)
          .setSearch(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TicketListState> async =
        ref.watch(ticketListControllerProvider(widget.scope));

    return Column(
      children: <Widget>[
        _Toolbar(
          searchOpen: _searchOpen,
          searchCtrl: _searchCtrl,
          onToggleSearch: () {
            setState(() => _searchOpen = !_searchOpen);
            if (!_searchOpen) {
              _searchCtrl.clear();
              _onSearchChanged('');
            }
          },
          onSearchChanged: _onSearchChanged,
          currentStatus: async.valueOrNull?.status,
          onStatusChanged: (TicketStatus? s) {
            ref
                .read(ticketListControllerProvider(widget.scope).notifier)
                .setStatusFilter(s);
          },
        ),
        Expanded(
          child: async.when(
            loading: () => const TicketListSkeleton(),
            error: (Object err, _) => ErrorState(
              message: 'Gagal memuat tiket.',
              details: err.toString(),
              onRetry: () => ref.invalidate(
                ticketListControllerProvider(widget.scope),
              ),
            ),
            data: (TicketListState s) {
              if (s.tickets.isEmpty) {
                final bool showCreateCta = widget.scope == TicketScope.mine &&
                    s.search.isEmpty;
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(ticketListControllerProvider(widget.scope)
                          .notifier)
                      .refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      const SizedBox(height: 64),
                      EmptyState(
                        title: 'Belum ada tiket',
                        subtitle: _emptyCopy(widget.scope, s.search),
                        icon: Icons.confirmation_num_outlined,
                        actionLabel:
                            showCreateCta ? 'Buat Tiket Baru' : null,
                        onAction: showCreateCta
                            ? () => context.push(AppRoutes.ticketCreate)
                            : null,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(ticketListControllerProvider(widget.scope).notifier)
                    .refresh(),
                child: ListView.builder(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: s.tickets.length + (s.hasMore ? 1 : 0),
                  itemBuilder: (BuildContext _, int i) {
                    if (i >= s.tickets.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      );
                    }
                    final TicketEntity t = s.tickets[i];
                    return TicketCard(
                      ticket: t,
                      onTap: () => context.push('/tickets/${t.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _emptyCopy(TicketScope scope, String search) {
    if (search.isNotEmpty) return 'Tidak ada hasil untuk "$search".';
    return switch (scope) {
      TicketScope.mine => 'Buat tiket pertama Anda dengan tombol di bawah.',
      TicketScope.assignedToMe =>
          'Belum ada tiket yang ditugaskan kepada Anda.',
      TicketScope.all => 'Belum ada tiket di sistem.',
    };
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchOpen,
    required this.searchCtrl,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  final bool searchOpen;
  final TextEditingController searchCtrl;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final TicketStatus? currentStatus;
  final ValueChanged<TicketStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: searchOpen
                    ? TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Cari judul atau nomor tiket...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                        ),
                        onChanged: onSearchChanged,
                        textInputAction: TextInputAction.search,
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: searchOpen ? 'Tutup pencarian' : 'Cari',
                onPressed: onToggleSearch,
                icon: Icon(searchOpen ? Icons.close : Icons.search),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: <Widget>[
              _StatusChip(
                label: 'Semua',
                selected: currentStatus == null,
                onTap: () => onStatusChanged(null),
              ),
              for (final String s in AppConstants.ticketStatuses)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _StatusChip(
                    label: AppLabels.status[s] ?? s,
                    selected: currentStatus?.wire == s,
                    onTap: () => onStatusChanged(TicketStatus.fromString(s)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

