/// Bar chart of tickets per category.
///
/// One bar per [TicketCategory] (in enum order), painted in the
/// primary brand color with a fade-in opacity ramp so the eye
/// flows left-to-right. The y-axis shows whole numbers only and the
/// x-axis labels use the Indonesian category labels from
/// [TicketCategory.label].
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../ticket/domain/entities/ticket_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

class StatBarChart extends StatelessWidget {
  const StatBarChart({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TicketCategory> categories = TicketCategory.values;
    final List<int> counts = <int>[
      for (final TicketCategory c in categories)
        stats.ticketsByCategory[c.wire] ?? 0,
    ];
    final int maxCount =
        counts.fold<int>(0, (int p, int c) => c > p ? c : p);

    if (maxCount == 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Belum ada tiket per kategori.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // Round the y-axis up to a sensible tick (max + 1, capped at +20%
    // headroom) so the tallest bar doesn't kiss the chart's top edge.
    final double maxY = (maxCount + 1).toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (double _) => FlLine(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value != value.toInt()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int i = value.toInt();
                  if (i < 0 || i >= categories.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      categories[i].label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (int i = 0; i < categories.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: counts[i].toDouble(),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    // Opacity ramp 0.55 -> 1.0 across the categories.
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.55 + (0.45 * (i / (categories.length - 1))),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
