/// Single shimmer-able rectangle. Used as the building block for
/// every list-row and screen-level skeleton in the app.
///
/// Wraps its child in a [Shimmer.fromColors] gradient sized to the
/// box. Colors are derived from the active theme so dark mode is
/// handled automatically without per-callsite branching.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width = double.infinity,
    this.height = 14,
    this.radius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final Color highlight =
        theme.colorScheme.onSurface.withValues(alpha: 0.18);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Convenience: a vertical stack of [SkeletonBox] rows wrapped in a
/// single [Shimmer.fromColors] so the gradient sweeps continuously
/// across the entire group instead of restarting per child.
class SkeletonGroup extends StatelessWidget {
  const SkeletonGroup({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final Color highlight =
        theme.colorScheme.onSurface.withValues(alpha: 0.18);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}

/// Plain rectangle (no shimmer) — child of a [SkeletonGroup]. Use
/// inside a group so the parent's gradient animates across all rows
/// uniformly.
class SkeletonShape extends StatelessWidget {
  const SkeletonShape({
    this.width = double.infinity,
    this.height = 14,
    this.radius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
