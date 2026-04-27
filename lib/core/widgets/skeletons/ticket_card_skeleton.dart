/// Placeholder card mirroring the shape of a `TicketTile` /
/// `HistoryTile`. Rendered N times during list loading.
library;

import 'package:flutter/material.dart';

import 'skeleton_box.dart';

class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: const SkeletonGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SkeletonShape(width: 90, height: 14, radius: 6),
                Spacer(),
                SkeletonShape(width: 60, height: 22, radius: 12),
              ],
            ),
            SizedBox(height: 12),
            SkeletonShape(height: 16, radius: 6),
            SizedBox(height: 8),
            SkeletonShape(width: 220, height: 14, radius: 6),
            SizedBox(height: 12),
            Row(
              children: <Widget>[
                SkeletonShape(width: 80, height: 24, radius: 12),
                SizedBox(width: 8),
                SkeletonShape(width: 80, height: 24, radius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TicketListSkeleton extends StatelessWidget {
  const TicketListSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (_, __) => const TicketCardSkeleton(),
    );
  }
}
