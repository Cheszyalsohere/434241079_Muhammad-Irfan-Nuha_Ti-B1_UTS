/// History screen (FR-010 — Riwayat Tiket).
///
/// Role-aware — the underlying provider already maps the current
/// user's role to the correct [TicketScope]:
///   • USER     → tiket yang dibuat saya
///   • HELPDESK → tiket yang ditugaskan ke saya
///   • ADMIN    → semua tiket
///
/// UI: app bar (title only), expandable search field, status filter
/// chips, paginated list of [HistoryTile] with pull-to-refresh and
/// infinite scroll. Tap a tile → push `/tickets/:id`. Empty / error
/// states use [EmptyState] / a small retry button.
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
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';
import '../providers/history_provider.dart';
import '../widgets/history_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
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
      ref.read(historyControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(historyControllerProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<HistoryState> async =
        ref.watch(historyControllerProvider);
    final UserEntity? user = ref.watch(currentUserProvider).valueOrNull;
    final UserRole role = user?.role ?? UserRole.user;
    final int unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Tiket'),
        actions: <Widget>[
          IconButton(
            tooltip: _searchOpen ? 'Tutup pencarian' : 'Cari',
            onPressed: () {
              setState(() => _searchOpen = !_searchOpen);
              if (!_searchOpen) {
                _searchCtrl.clear();
                _onSearchChanged('');
              }
            },
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _Toolbar(
              searchOpen: _searchOpen,
              searchCtrl: _searchCtrl,
              onSearchChanged: _onSearchChanged,
              currentStatus: async.valueOrNull?.status,
              onStatusChanged: (TicketStatus? s) {
                ref
                    .read(historyControllerProvider.notifier)
                    .setStatusFilter(s);
              },
            ),
            Expanded(
              child: async.when(
                loading: () => const TicketListSkeleton(),
                error: (Object err, _) => ErrorState(
                  message: 'Gagal memuat riwayat.',
                  details: err.toString(),
                  onRetry: () =>
                      ref.invalidate(historyControllerProvider),
                ),
                data: (HistoryState s) {
                  if (s.tickets.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(historyControllerProvider.notifier)
                          .refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          const SizedBox(height: 64),
                          EmptyState(
                            title: 'Belum ada riwayat',
                            subtitle: _emptyCopy(role, s),
                            icon: Icons.history_toggle_off,
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(historyControllerProvider.notifier)
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                            ),
                          );
                        }
                        final TicketEntity t = s.tickets[i];
                        return HistoryTile(
                          ticket: t,
                          viewerRole: role,
                          onTap: () => context.push('/tickets/${t.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyCopy(UserRole role, HistoryState s) {
    if (s.search.isNotEmpty) {
      return 'Tidak ada hasil untuk "${s.search}".';
    }
    if (s.status != null) {
      return 'Tidak ada tiket dengan status "${s.status!.label}".';
    }
    return switch (role) {
      UserRole.user =>
          'Buat tiket pertama Anda dan lacak progresnya di sini.',
      UserRole.helpdesk =>
          'Belum ada tiket yang ditugaskan kepada Anda.',
      UserRole.admin => 'Belum ada tiket di sistem.',
    };
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchOpen,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  final bool searchOpen;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final TicketStatus? currentStatus;
  final ValueChanged<TicketStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari judul atau nomor tiket...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
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

