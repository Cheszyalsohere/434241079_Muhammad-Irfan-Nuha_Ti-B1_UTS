/// Full-bleed mesh gradient that sits behind every screen.
///
/// Rendered once at the MaterialApp level via `builder:` so the
/// transparent `Scaffold` + `AppBar` can float on top. The two blurred
/// circles give the backdrop a soft "mesh" feel without any image
/// assets — pure `DecoratedBox` + `ImageFilter.blur`.
///
/// Light mode: indigo-100 → pink-100 → cyan-100 (top-left to
/// bottom-right). Dark mode: indigo-950 → pink-900 → cyan-900.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Paints a mesh-style gradient backdrop and places [child] above it.
///
/// Intended for use inside `MaterialApp.router`'s `builder:` so every
/// route inherits the same backdrop, and `Scaffold`s can stay
/// transparent.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> colors = dark
        ? const <Color>[
            AppColors.gradientDark1,
            AppColors.gradientDark2,
            AppColors.gradientDark3,
          ]
        : const <Color>[
            AppColors.gradientLight1,
            AppColors.gradientLight2,
            AppColors.gradientLight3,
          ];

    return Stack(
      children: <Widget>[
        // Base gradient — full bleed.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
        ),
        // Top-right "mesh" bloom — extra saturation in the secondary
        // hue, blurred aggressively so it reads as atmosphere, not a
        // shape.
        Positioned(
          top: -120,
          right: -80,
          child: _Bloom(
            size: 320,
            color: (dark ? AppColors.secondary : AppColors.secondary)
                .withValues(alpha: dark ? 0.25 : 0.35),
          ),
        ),
        // Bottom-left bloom in the tertiary hue.
        Positioned(
          bottom: -140,
          left: -100,
          child: _Bloom(
            size: 360,
            color: AppColors.tertiary.withValues(alpha: dark ? 0.25 : 0.30),
          ),
        ),
        // Foreground.
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
