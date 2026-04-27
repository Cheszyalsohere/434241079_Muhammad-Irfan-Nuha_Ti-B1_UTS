/// Placeholder mirroring `ProfileScreen`'s header card + info rows.
library;

import 'package:flutter/material.dart';

import 'skeleton_box.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        // Header card with circular avatar + name/role bars.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: const SkeletonGroup(
            child: Column(
              children: <Widget>[
                SkeletonShape(width: 96, height: 96, radius: 48),
                SizedBox(height: 16),
                SkeletonShape(width: 180, height: 18, radius: 6),
                SizedBox(height: 8),
                SkeletonShape(width: 100, height: 24, radius: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Info rows.
        for (int i = 0; i < 4; i++) ...<Widget>[
          Container(
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
                children: <Widget>[
                  SkeletonShape(width: 24, height: 24, radius: 6),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SkeletonShape(width: 80, height: 10, radius: 4),
                        SizedBox(height: 8),
                        SkeletonShape(height: 14, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
