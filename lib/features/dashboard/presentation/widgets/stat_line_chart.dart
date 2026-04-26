/// Line chart for the 7-day "tickets created" trend.
///
/// Plots [DashboardStats.ticketsPerDay] (always seven points, oldest
/// to newest) with the primary brand color and a soft gradient fill
/// underneath. X-axis labels are short Indonesian weekday names
/// (Sen/Sel/Rab/Kam/Jum/Sab/Min) so the chart reads at a glance.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/tickets_per_day_entity.dart';

class StatLineChart extends StatelessWidget {
  const StatLineChart({super.key, required this.stats});

  final DashboardStats stats;

  /// Indonesian short weekday names. `DateTime.weekday` is 1..7 with
  /// 1 = Monday, so we index `_dayLabels[d.weekday - 1]`.
  static const List<String> _dayLabels = <String>[
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TicketsPerDay> series = stats.ticketsPerDay;

    if (series.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Belum ada tren tiket.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    final int maxCount =
        series.fold<int>(0, (int p, TicketsPerDay e) => e.count > p ? e.count : p);
    // Headroom — the chart looks better when the line never touches
    // the top edge. Cap min at 4 so a flat-zero series still shows
    // gridlines, not a single line glued to the x-axis.
    final double maxY = (maxCount < 4 ? 4 : maxCount + 1).toDouble();

    final List<FlSpot> spots = <FlSpot>[
      for (int i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].count.toDouble()),
    ];

    final Color primary = theme.colorScheme.primary;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (series.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
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
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int i = value.toInt();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  final DateTime d = series[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _dayLabels[d.weekday - 1],
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
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (FlSpot _, double __, LineChartBarData ___,
                        int ____) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    primary.withValues(alpha: 0.30),
                    primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> spots) => spots
                  .map(
                    (LineBarSpot s) => LineTooltipItem(
                      '${s.y.toInt()} tiket',
                      theme.textTheme.labelSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}
