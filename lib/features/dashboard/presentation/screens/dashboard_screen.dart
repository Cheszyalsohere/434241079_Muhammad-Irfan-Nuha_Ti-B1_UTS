/// Dashboard screen (FR-008) — role-aware analytics overview.
///
/// Sections (top to bottom):
///   • AppBar with notifications + profile actions
///   • Greeting card (current user name + role)
///   • Role-specific KPI grid:
///       USER     → "Tiket Saya" + Open + In-progress + Resolved
///       HELPDESK → "Assigned to Me" + Open + In-progress + Avg Resolution
///       ADMIN    → Total Tiket + Open + In-progress + Avg Resolution +
///                  Total Pengguna + Total Helpdesk
///   • Status pie chart (donut + center total + legend)
///   • Tickets-per-category bar chart (HELPDESK + ADMIN only)
///   • 7-day trend line chart (HELPDESK + ADMIN only)
///   • FAB → /tickets/create — visible only for the basic `user` role
///
/// Loading uses `shimmer` placeholders that mirror the final layout
/// shape, so the page doesn't jump around when data lands.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../shared/widgets/app_menu_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/kpi_card.dart';
import '../widgets/stat_bar_chart.dart';
import '../widgets/stat_line_chart.dart';
import '../widgets/stat_pie_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DashboardStats> async =
        ref.watch(dashboardControllerProvider);
    final UserEntity? user = ref.watch(currentUserProvider).valueOrNull;
    final UserRole role = user?.role ?? UserRole.user;
    // Both regular users AND admins can create tickets. Helpdesk
    // staff don't — they handle existing tickets, not raise new ones.
    final bool canCreateTickets =
        role == UserRole.user || role == UserRole.admin;
    final int unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Notifikasi',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          const AppMenuButton(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
          child: async.when(
            loading: () => const DashboardSkeleton(),
            error: (Object err, _) => _DashboardError(
              message: err.toString(),
              onRetry: () => ref.invalidate(dashboardControllerProvider),
            ),
            data: (DashboardStats stats) => _DashboardBody(
              user: user,
              stats: stats,
            ),
          ),
        ),
      ),
      floatingActionButton: canCreateTickets
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.ticketCreate),
              icon: const Icon(Icons.add),
              label: const Text('Tiket Baru'),
            )
          : null,
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.user, required this.stats});

  final UserEntity? user;
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final UserRole role = user?.role ?? UserRole.user;
    final bool showOpsCharts = role.canManageAllTickets;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        _Greeting(user: user),
        const SizedBox(height: 16),

        // KPI grid — content varies by role.
        _RoleKpiGrid(role: role, stats: stats),
        const SizedBox(height: 16),

        // Status distribution — every role gets the pie.
        _Section(
          title: 'Distribusi Status',
          child: StatPieChart(stats: stats),
        ),

        // Operational charts (helpdesk + admin only). The basic user
        // doesn't need a per-category breakdown of just their own
        // handful of tickets.
        if (showOpsCharts) ...<Widget>[
          const SizedBox(height: 16),
          _Section(
            title: 'Tiket per Kategori',
            child: StatBarChart(stats: stats),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Tren 7 Hari Terakhir',
            subtitle: 'Tiket baru per hari',
            child: StatLineChart(stats: stats),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = user?.fullName ?? 'Pengguna';
    final UserRole role = user?.role ?? UserRole.user;
    final String roleLabel = switch (role) {
      UserRole.admin => 'Admin',
      UserRole.helpdesk => 'Tim Helpdesk',
      UserRole.user => 'Pengguna',
    };
    final String summaryLine = switch (role) {
      UserRole.admin => 'Ringkasan seluruh tiket di sistem',
      UserRole.helpdesk => 'Ringkasan tiket yang ditugaskan ke Anda',
      UserRole.user => 'Ringkasan tiket Anda',
    };

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Halo, $name',
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  summaryLine,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role-specific KPI grid ────────────────────────────────────────────

class _RoleKpiGrid extends StatelessWidget {
  const _RoleKpiGrid({required this.role, required this.stats});

  final UserRole role;
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;

    // Build the list of cards declaratively per role; render in a
    // 2-per-row grid below.
    final List<Widget> cards = switch (role) {
      UserRole.user => <Widget>[
          KpiCard(
            label: 'Tiket Saya',
            value: '${stats.total}',
            icon: Icons.confirmation_number_outlined,
            accent: primary,
            onTap: () => context.push(AppRoutes.tickets),
          ),
          KpiCard(
            label: 'Terbuka',
            value: '${stats.open}',
            icon: Icons.error_outline,
            accent: AppColors.statusOpen,
          ),
          KpiCard(
            label: 'Diproses',
            value: '${stats.inProgress}',
            icon: Icons.timelapse_outlined,
            accent: AppColors.statusInProgress,
          ),
          KpiCard(
            label: 'Selesai',
            value: '${stats.resolved}',
            icon: Icons.check_circle_outline,
            accent: AppColors.statusResolved,
          ),
        ],
      UserRole.helpdesk => <Widget>[
          KpiCard(
            label: 'Ditugaskan ke Saya',
            value: '${stats.total}',
            icon: Icons.assignment_ind_outlined,
            accent: primary,
            onTap: () => context.push(AppRoutes.tickets),
          ),
          KpiCard(
            label: 'Terbuka',
            value: '${stats.open}',
            icon: Icons.error_outline,
            accent: AppColors.statusOpen,
          ),
          KpiCard(
            label: 'Diproses',
            value: '${stats.inProgress}',
            icon: Icons.timelapse_outlined,
            accent: AppColors.statusInProgress,
          ),
          KpiCard(
            label: 'Rata-rata Resolusi',
            value: _formatHours(stats.avgResolutionHours),
            subtitle: 'dari tiket selesai',
            icon: Icons.speed_outlined,
            accent: AppColors.tertiary,
          ),
        ],
      UserRole.admin => <Widget>[
          KpiCard(
            label: 'Total Tiket',
            value: '${stats.total}',
            icon: Icons.confirmation_number_outlined,
            accent: primary,
            onTap: () => context.push(AppRoutes.tickets),
          ),
          KpiCard(
            label: 'Terbuka',
            value: '${stats.open}',
            icon: Icons.error_outline,
            accent: AppColors.statusOpen,
          ),
          KpiCard(
            label: 'Diproses',
            value: '${stats.inProgress}',
            icon: Icons.timelapse_outlined,
            accent: AppColors.statusInProgress,
          ),
          KpiCard(
            label: 'Rata-rata Resolusi',
            value: _formatHours(stats.avgResolutionHours),
            subtitle: 'dari tiket selesai',
            icon: Icons.speed_outlined,
            accent: AppColors.tertiary,
          ),
          KpiCard(
            label: 'Total Pengguna',
            value: '${stats.totalUsers}',
            icon: Icons.people_outline,
            accent: AppColors.secondary,
          ),
          KpiCard(
            label: 'Total Helpdesk',
            value: '${stats.totalHelpdesk}',
            icon: Icons.support_agent_outlined,
            accent: AppColors.statusResolved,
          ),
        ],
    };

    return _Grid(children: cards);
  }

  /// Pretty-print average resolution. Below 1 hour render minutes; an
  /// empty dataset prints "—" so the card doesn't mislead with "0 jam".
  static String _formatHours(double hours) {
    if (hours <= 0) return '—';
    if (hours < 1) return '${(hours * 60).round()} mnt';
    if (hours < 10) return '${hours.toStringAsFixed(1)} jam';
    return '${hours.round()} jam';
  }
}

/// Two-column adaptive grid that lays out an arbitrary card list. We
/// avoid `GridView` here because we're inside a parent `ListView` and
/// don't want nested-scroll headaches.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final Widget left = children[i];
      final Widget? right =
          i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < children.length ? 12 : 0),
          child: Row(
            children: <Widget>[
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ── Error ─────────────────────────────────────────────────────────────

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 56),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboard);
          case 1:
            context.go(AppRoutes.tickets);
          case 2:
            context.go(AppRoutes.history);
          case 3:
            context.go(AppRoutes.profile);
        }
      },
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number),
          label: 'Tiket',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
