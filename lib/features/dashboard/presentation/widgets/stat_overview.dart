/// Dashboard stat overview — a dark "hero" card showing the headline
/// count + a 7-day sparkline, followed by a dense breakdown card with
/// status rows (coloured dot, label, progress bar, count) and a set of
/// secondary metric rows.
///
/// Replaces the old empty-feeling 2×2 KPI grid. Content varies by role:
///   USER     → headline "Tiket Saya"
///   HELPDESK → headline "Ditugaskan ke Saya" + avg resolution
///   ADMIN    → headline "Total Tiket" + avg resolution + people counts
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/tickets_per_day_entity.dart';

class StatOverview extends StatelessWidget {
  const StatOverview({
    super.key,
    required this.role,
    required this.stats,
    this.onTapHeadline,
  });

  final UserRole role;
  final DashboardStats stats;
  final VoidCallback? onTapHeadline;

  String get _headlineLabel => switch (role) {
        UserRole.user => 'Tiket Saya',
        UserRole.helpdesk => 'Ditugaskan ke Saya',
        UserRole.admin => 'Total Tiket',
      };

  @override
  Widget build(BuildContext context) {
    final bool showOps = role != UserRole.user;
    final int weekNew =
        stats.ticketsPerDay.fold<int>(0, (int s, TicketsPerDay d) => s + d.count);

    return Column(
      children: <Widget>[
        _Hero(
          value: stats.total,
          label: _headlineLabel,
          weekNew: weekNew,
          series: stats.ticketsPerDay,
          onTap: onTapHeadline,
        ),
        const SizedBox(height: 11),
        _BreakdownCard(
          stats: stats,
          showAvgResolution: showOps,
          showPeopleCounts: role == UserRole.admin,
        ),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.value,
    required this.label,
    required this.weekNew,
    required this.series,
    this.onTap,
  });

  final int value;
  final String label;
  final int weekNew;
  final List<TicketsPerDay> series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = AppColors.inkButton(dark);
    final Color onInk = AppColors.onInkButton(dark);
    final BorderRadius radius = BorderRadius.circular(14);

    final Widget card = Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: radius,
        boxShadow: AppColors.restShadow(dark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '$value',
                  style: AppTextStyles.monoLarge.copyWith(
                    color: onInk,
                    fontSize: 44,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(
                    color: onInk.withValues(alpha: 0.6),
                  ),
                ),
                if (weekNew > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.arrow_outward,
                          size: 13, color: onInk.withValues(alpha: 0.55)),
                      const SizedBox(width: 3),
                      Text(
                        '$weekNew tiket · 7 hari terakhir',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: onInk.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (series.isNotEmpty)
            SizedBox(
              width: 96,
              height: 48,
              child: CustomPaint(
                painter: _SparkPainter(
                  series: series,
                  color: onInk,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}

/// Bar sparkline — last entry highlighted, the rest muted.
class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.series, required this.color});

  final List<TicketsPerDay> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final int maxCount =
        series.map((TicketsPerDay d) => d.count).fold<int>(1, (int a, int b) => a > b ? a : b);
    final int n = series.length;
    const double gap = 4;
    final double barW = (size.width - gap * (n - 1)) / n;
    final double minH = 3;

    for (int i = 0; i < n; i++) {
      final double t = series[i].count / maxCount;
      final double h = (minH + t * (size.height - minH)).clamp(minH, size.height);
      final double x = i * (barW + gap);
      final double y = size.height - h;
      final bool isLast = i == n - 1;
      final Paint p = Paint()
        ..color = color.withValues(alpha: isLast ? 1.0 : 0.28)
        ..style = PaintingStyle.fill;
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(r, p);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.series != series || old.color != color;
}

// ── Breakdown card ────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.stats,
    required this.showAvgResolution,
    required this.showPeopleCounts,
  });

  final DashboardStats stats;
  final bool showAvgResolution;
  final bool showPeopleCounts;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color fill = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color border = dark ? AppColors.borderDark : AppColors.borderLight;
    final int denom = stats.total == 0 ? 1 : stats.total;

    final List<Widget> rows = <Widget>[
      _StatusRow(
        label: 'Terbuka',
        count: stats.open,
        fraction: stats.open / denom,
        color: AppColors.statusOpen,
      ),
      _StatusRow(
        label: 'Diterima',
        count: stats.assigned,
        fraction: stats.assigned / denom,
        color: AppColors.statusAssigned,
      ),
      _StatusRow(
        label: 'Diproses',
        count: stats.inProgress,
        fraction: stats.inProgress / denom,
        color: AppColors.statusInProgress,
      ),
      _StatusRow(
        label: 'Ditutup',
        count: stats.closed,
        fraction: stats.closed / denom,
        color: AppColors.statusClosed,
      ),
    ];

    final List<Widget> secondary = <Widget>[
      if (showAvgResolution)
        _MetricRow(
          icon: Icons.speed_outlined,
          label: 'Rata-rata Resolusi',
          value: _formatHours(stats.avgResolutionHours),
        ),
      if (showPeopleCounts) ...<Widget>[
        _MetricRow(
          icon: Icons.people_outline,
          label: 'Total Pengguna',
          value: '${stats.totalUsers}',
        ),
        _MetricRow(
          icon: Icons.support_agent_outlined,
          label: 'Total Helpdesk',
          value: '${stats.totalHelpdesk}',
        ),
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: AppColors.restShadow(dark),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, thickness: 1, color: border),
            rows[i],
          ],
          if (secondary.isNotEmpty) ...<Widget>[
            Container(height: 6, color: dark
                ? AppColors.surfaceAltDark
                : AppColors.surfaceAltLight),
            for (int i = 0; i < secondary.length; i++) ...<Widget>[
              if (i > 0) Divider(height: 1, thickness: 1, color: border),
              secondary[i],
            ],
          ],
        ],
      ),
    );
  }

  static String _formatHours(double hours) {
    if (hours <= 0) return '—';
    if (hours < 1) return '${(hours * 60).round()} mnt';
    if (hours < 10) return '${hours.toStringAsFixed(1)} jam';
    return '${hours.round()} jam';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Progress track.
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: count == 0 ? 0 : fraction.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 26,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: AppTextStyles.monoMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 17,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.monoMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
