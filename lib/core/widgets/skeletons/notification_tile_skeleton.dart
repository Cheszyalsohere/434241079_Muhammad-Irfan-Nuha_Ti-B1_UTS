/// Placeholder row mirroring `NotificationTile`. Rendered while the
/// notification list is loading.
library;

import 'package:flutter/material.dart';

import 'skeleton_box.dart';

class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: const SkeletonGroup(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SkeletonShape(width: 36, height: 36, radius: 18),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonShape(height: 14, radius: 6, width: 200),
                  SizedBox(height: 8),
                  SkeletonShape(height: 12, radius: 6),
                  SizedBox(height: 6),
                  SkeletonShape(height: 12, radius: 6, width: 140),
                  SizedBox(height: 8),
                  SkeletonShape(width: 80, height: 10, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (_, __) => const NotificationTileSkeleton(),
    );
  }
}
