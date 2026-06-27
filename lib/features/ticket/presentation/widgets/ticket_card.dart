/// List item rendering a ticket summary: mono ticket number + relative
/// time (top row), title, truncated description, status/priority badges,
/// category, and assignee. A slim status-coloured rule on the left edge
/// gives the list a scannable rhythm. Tap fires [onTap].
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/ticket_entity.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({required this.ticket, this.onTap, super.key});

  final TicketEntity ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color fill = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color stroke = dark ? AppColors.borderDark : AppColors.borderLight;
    final Color statusColor = AppColors.statusColor(ticket.status.wire);
    final BorderRadius radius = BorderRadius.circular(12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: fill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: stroke),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Status accent rule.
                  Container(width: 3, color: statusColor.withValues(alpha: 0.85)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Header: mono ticket number + relative time.
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  ticket.ticketNumber,
                                  style: AppTextStyles.monoSmall.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormatter.relative(ticket.updatedAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            ticket.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Badges row.
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              StatusBadge(
                                value: ticket.status.wire,
                                kind: BadgeKind.status,
                              ),
                              StatusBadge(
                                value: ticket.priority.wire,
                                kind: BadgeKind.priority,
                              ),
                              _CategoryChip(label: ticket.category.label),
                              if (ticket.attachmentUrl != null)
                                Icon(
                                  Icons.attachment_outlined,
                                  size: 15,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                            ],
                          ),
                          if (ticket.assignedToProfile != null) ...<Widget>[
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.person_outline,
                                  size: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    ticket.assignedToProfile!.fullName,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
