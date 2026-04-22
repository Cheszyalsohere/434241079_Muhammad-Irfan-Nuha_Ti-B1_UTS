/// Frosted-glass surface primitives.
///
/// [GlassContainer] paints a translucent, backdrop-blurred rectangle
/// with a hairline border — the basic building block for every glass
/// surface in the app (cards, sheets, toolbars, composers).
///
/// [GlassCard] is a thin ergonomic wrapper that adds an `onTap` hit
/// region and standard padding/radius, so list cards can drop in
/// without repeating the `Material + InkWell + ClipRRect` dance.
///
/// Both widgets are theme-aware: on dark mode they swap to the dark
/// glass tokens from [AppColors], so the frost reads correctly against
/// the dark mesh gradient.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A translucent, blurred rectangle — the universal glass surface.
///
/// Usage:
/// ```dart
/// GlassContainer(
///   padding: EdgeInsets.all(16),
///   child: Text('Hello'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 18,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Corner radius of the frosted rectangle. Defaults to 20 (between
  /// the `md` and `lg` tokens) — a pleasant middle ground for cards.
  final double borderRadius;

  /// Sigma for the backdrop blur. Higher = dreamier; 18 is the sweet
  /// spot where text on top is still crisp.
  final double blurSigma;

  /// Optional override for the translucent fill. When omitted we pick
  /// the correct light/dark glass token from [AppColors].
  final Color? backgroundColor;

  /// Optional override for the hairline border.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color fill = backgroundColor ??
        (dark ? AppColors.glassSurfaceDark : AppColors.glassSurfaceLight);
    final Color stroke = borderColor ??
        (dark ? AppColors.glassBorderDark : AppColors.glassBorderLight);
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(color: stroke, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass surface tuned for list/grid cards. Wraps [GlassContainer]
/// with an optional tap target (ripple stays visible over the frost
/// because we paint the `InkWell` above the blur).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.borderRadius = 20,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.glassSurfaceDark
                : AppColors.glassSurfaceLight,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorderLight,
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
