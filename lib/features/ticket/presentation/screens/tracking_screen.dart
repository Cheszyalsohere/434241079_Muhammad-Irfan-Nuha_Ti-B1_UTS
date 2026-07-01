/// Tracking Tiket screen (FR-011 / SRS §5.8) — a dedicated view of a
/// ticket's status journey, separate from the detail screen.
///
/// Layout:
///   1. Header card  — mono ticket number + title + current status badge
///   2. Workflow stepper — the four-stage lifecycle (Terbuka → Diproses
///      → Selesai → Ditutup) with the current stage highlighted; the
///      signature "tracking" visual.
///   3. Timeline     — the reused [StatusTimeline] showing every actual
///      status change, oldest first.
///
/// Reuses [ticketDetailControllerProvider] so the data is consistent
/// with (and cached alongside) the detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/usecases/get_ticket_detail_usecase.dart';
import '../providers/ticket_detail_provider.dart';
import '../widgets/status_timeline.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TicketDetail> async =
        ref.watch(ticketDetailControllerProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.tickets);
            }
          },
        ),
        title: const Text('Tracking Tiket'),
      ),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'Memuat tracking...'),
        error: (Object e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(ticketDetailControllerProvider(ticketId)),
        ),
        data: (TicketDetail d) => RefreshIndicator(
          onRefresh: () => ref
              .read(ticketDetailControllerProvider(ticketId).notifier)
              .refresh(),
          child: ResponsiveCenter(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                _HeaderCard(ticket: d.ticket),
                const SizedBox(height: 12),
                _WorkflowStepper(current: d.ticket.status),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Riwayat Perubahan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 14),
                      StatusTimeline(ticket: d.ticket, history: d.history),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.ticket});
  final TicketEntity ticket;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ticket.ticketNumber,
            style: AppTextStyles.monoSmall.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(ticket.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                'Status saat ini',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              StatusBadge(value: ticket.status.wire, kind: BadgeKind.status),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Workflow stepper ──────────────────────────────────────────────────

/// Horizontal four-stage lifecycle indicator. Stages up to and including
/// the ticket's current status read as "reached"; later stages are muted.
class _WorkflowStepper extends StatelessWidget {
  const _WorkflowStepper({required this.current});
  final TicketStatus current;

  static const List<TicketStatus> _stages = <TicketStatus>[
    TicketStatus.open,
    TicketStatus.assigned,
    TicketStatus.inProgress,
    TicketStatus.closed,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int currentIndex = _stages.indexOf(current);
    final Color muted = theme.colorScheme.onSurface.withValues(alpha: 0.18);

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < _stages.length; i++)
            Expanded(
              child: _Stage(
                status: _stages[i],
                reached: i <= currentIndex,
                isCurrent: i == currentIndex,
                connectorBeforeColor: i == 0
                    ? Colors.transparent
                    : (i <= currentIndex
                        ? AppColors.statusColor(_stages[i].wire)
                        : muted),
                connectorAfterColor: i == _stages.length - 1
                    ? Colors.transparent
                    : (i < currentIndex
                        ? AppColors.statusColor(_stages[i + 1].wire)
                        : muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.status,
    required this.reached,
    required this.isCurrent,
    required this.connectorBeforeColor,
    required this.connectorAfterColor,
  });

  final TicketStatus status;
  final bool reached;
  final bool isCurrent;
  final Color connectorBeforeColor;
  final Color connectorAfterColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = AppColors.statusColor(status.wire);
    final Color nodeColor = reached ? color : Colors.transparent;
    final Color borderColor =
        reached ? color : theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return Column(
      children: <Widget>[
        // Row: connector — node — connector.
        Row(
          children: <Widget>[
            Expanded(child: Container(height: 2, color: connectorBeforeColor)),
            Container(
              width: isCurrent ? 26 : 22,
              height: isCurrent ? 26 : 22,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: isCurrent
                    ? <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: reached
                  ? Icon(
                      isCurrent ? Icons.adjust : Icons.check,
                      size: isCurrent ? 15 : 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            Expanded(child: Container(height: 2, color: connectorAfterColor)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLabels.status[status.wire] ?? status.wire,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: reached
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
