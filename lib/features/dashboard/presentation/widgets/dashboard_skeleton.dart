/// Shimmer placeholder mirroring the dashboard's final layout shape.
///
/// Rendered while [DashboardController] is in `loading`. Keeping the
/// skeleton's silhouette close to the data view means the page
/// doesn't jump around when the real cards land.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final Color highlight =
        theme.colorScheme.onSurface.withValues(alpha: 0.18);

    Widget bar({required double height, double? width, double radius = 12}) =>
        Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          // Greeting placeholder.
          bar(height: 80, radius: 20),
          const SizedBox(height: 16),
          // KPI grid (2×2).
          Row(
            children: <Widget>[
              Expanded(child: bar(height: 110, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: bar(height: 110, radius: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: bar(height: 110, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: bar(height: 110, radius: 20)),
            ],
          ),
          const SizedBox(height: 16),
          // Pie placeholder.
          bar(height: 220, radius: 20),
          const SizedBox(height: 16),
          // Bar placeholder.
          bar(height: 220, radius: 20),
          const SizedBox(height: 16),
          // Line placeholder.
          bar(height: 220, radius: 20),
        ],
      ),
    );
  }
}
