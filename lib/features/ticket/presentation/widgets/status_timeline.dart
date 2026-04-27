/// Vertical status-change timeline (FR-011).
///
/// Renders one node per [StatusHistoryEntry] for the given ticket.
/// Each node has a colored dot (matching the *new* status color) and
/// a vertical connector to the next node. The body shows:
///   • old → new status transition
///   • who made the change (full name; "Sistem" if missing)
///   • optional notes
///   • relative timestamp
///
/// The first node is always synthesized as "Tiket Dibuat" using
/// `ticket.createdAt`, unless the history list already starts with a
/// row whose `oldStatus == null` (the DB trigger fires one such row
/// on ticket creation, and we don't want to render it twice).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/ticket_entity.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.ticket,
    required this.history,
  });

  final TicketEntity ticket;
  final List<StatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final List<_TimelineNode> nodes = _buildNodes();

    if (nodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada perubahan status.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < nodes.length; i++)
          _TimelineRow(
            node: nodes[i],
            isFirst: i == 0,
            isLast: i == nodes.length - 1,
          ),
      ],
    );
  }

  /// Build the visual node list. Always includes a synthetic creation
  /// node when the history doesn't already represent it, so the
  /// timeline reads chronologically from "Tiket Dibuat" forward.
  List<_TimelineNode> _buildNodes() {
    final List<_TimelineNode> nodes = <_TimelineNode>[];

    // Decide whether to prepend a synthetic creation node. The DB
    // trigger inserts a row with `old_status = null` on ticket
    // creation; when present we skip the synthetic to avoid a
    // duplicate.
    final bool historyHasCreation =
        history.isNotEmpty && history.first.oldStatus == null;

    if (!historyHasCreation) {
      nodes.add(
        _TimelineNode(
          label: 'Tiket Dibuat',
          subtitle: ticket.createdByProfile?.fullName ?? 'Pemohon',
          notes: null,
          status: TicketStatus.open,
          when: ticket.createdAt,
        ),
      );
    }

    for (final StatusHistoryEntry h in history) {
      final String who = h.changedByProfile?.fullName ?? 'Sistem';
      final String label = h.oldStatus == null
          ? 'Tiket Dibuat (${h.newStatus.label})'
          : '${h.oldStatus!.label} → ${h.newStatus.label}';
      nodes.add(
        _TimelineNode(
          label: label,
          subtitle: who,
          notes: h.notes,
          status: h.newStatus,
          when: h.createdAt,
        ),
      );
    }

    return nodes;
  }
}

/// One visual row: dot + connector on the left, content on the right.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.node,
    required this.isFirst,
    required this.isLast,
  });

  final _TimelineNode node;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = AppColors.statusColor(node.status.wire);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Rail: top connector + dot + bottom connector. Hidden ends
          // produce the open caps on the first/last rows.
          SizedBox(
            width: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.30),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content card.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          node.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.relative(node.when),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'oleh ${node.subtitle}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (node.notes != null && node.notes!.trim().isNotEmpty)
                    ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        node.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineNode {
  const _TimelineNode({
    required this.label,
    required this.subtitle,
    required this.notes,
    required this.status,
    required this.when,
  });

  final String label;
  final String subtitle;
  final String? notes;
  final TicketStatus status;
  final DateTime when;
}
