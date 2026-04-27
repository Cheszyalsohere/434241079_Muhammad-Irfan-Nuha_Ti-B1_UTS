/// Compact history list item — purpose-built for the "Riwayat Tiket"
/// screen (FR-010). Renders ticket number, title, status + priority
/// chips, the actor that matters in this context (creator for staff,
/// assignee for users), and a relative `updated_at` timestamp.
///
/// We don't reuse [TicketCard] verbatim because the history surface
/// emphasises "what changed and when" rather than the description
/// preview — denser layout, smaller chips, no description blob.
library;

import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.ticket,
    required this.viewerRole,
    required this.onTap,
  });

  final TicketEntity ticket;
  final UserRole viewerRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // For users: who handled it (assignee). For staff: who created it.
    final UserEntity? counterparty = viewerRole.isUser
        ? ticket.assignedToProfile
        : ticket.createdByProfile;
    final String counterpartyLabel = counterparty?.fullName ??
        (viewerRole.isUser ? 'Belum ditugaskan' : 'Pemohon');
    final IconData counterpartyIcon = viewerRole.isUser
        ? Icons.support_agent_outlined
        : Icons.person_outline;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header: ticket number + relative updated_at.
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  ticket.ticketNumber,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.history,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormatter.relative(ticket.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ticket.title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              StatusBadge(
                value: ticket.status.wire,
                kind: BadgeKind.status,
              ),
              StatusBadge(
                value: ticket.priority.wire,
                kind: BadgeKind.priority,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                counterpartyIcon,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  counterpartyLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ticket.category.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
