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
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../shared/widgets/app_menu_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/stat_bar_chart.dart';
import '../widgets/stat_line_chart.dart';
import '../widgets/stat_overview.dart';
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

    return ResponsiveCenter(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          _Greeting(user: user),
          const SizedBox(height: 16),

          // Headline hero + dense status breakdown — varies by role.
          StatOverview(
            role: role,
            stats: stats,
            onTapHeadline: () => context.push(AppRoutes.tickets),
          ),
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
      ),
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
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Eyebrow + role chip on one line.
          Row(
            children: <Widget>[
              Text(
                'RINGKASAN',
                style: AppTextStyles.eyebrow.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  roleLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.14),
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 13),
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
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      child: ListView(
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
      ),
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
