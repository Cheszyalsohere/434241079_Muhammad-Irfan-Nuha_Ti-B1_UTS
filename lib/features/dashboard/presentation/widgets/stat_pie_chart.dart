/// Donut pie chart for ticket status distribution.
///
/// Layout: a fixed-size donut on the left with the total count
/// rendered inside the center hole, and a status legend (one row per
/// status) on the right. Each slice is keyed by [TicketStatus] and
/// colored from [AppColors.statusColor], so the chart's palette stays
/// in sync with the badges/chips elsewhere. Falls back to an empty-
/// state hint when there are zero tickets.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../ticket/domain/entities/ticket_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import 'chart_legend_item.dart';

class StatPieChart extends StatelessWidget {
  const StatPieChart({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (stats.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Belum ada data untuk ditampilkan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    final Map<TicketStatus, int> by = stats.byStatus;
    final List<MapEntry<TicketStatus, int>> entries = by.entries
        .where((MapEntry<TicketStatus, int> e) => e.value > 0)
        .toList(growable: false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Donut with the total count in the hole.
        SizedBox(
          height: 180,
          width: 180,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: <PieChartSectionData>[
                    for (final MapEntry<TicketStatus, int> e in entries)
                      PieChartSectionData(
                        value: e.value.toDouble(),
                        color: AppColors.statusColor(e.key.wire),
                        title: '',
                        radius: 32,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${stats.total}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Total',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Legend with counts + percentages.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final TicketStatus s in TicketStatus.values)
                ChartLegendItem(
                  color: AppColors.statusColor(s.wire),
                  label: s.label,
                  count: by[s] ?? 0,
                  total: stats.total,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
