/// Clean solid background that sits behind every screen.
///
/// Minimal-clean direction: no gradient blobs, no noise. Just a flat
/// off-white (light) / near-black (dark) page surface so content and
/// generous whitespace do the work. Painted once at the MaterialApp
/// `builder:` level so transparent Scaffolds float on top.
///
/// (Class name kept as `GradientBackground` so `app.dart` needs no
/// change — the surface is just solid now.)
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? AppColors.bgDark : AppColors.bgLight,
      child: child,
    );
  }
}
