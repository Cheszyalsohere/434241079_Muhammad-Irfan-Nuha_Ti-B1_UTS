/// Solid surface card primitives — replaces glassmorphism.
///
/// [GlassContainer] is now a crisp solid-fill card with a hairline
/// border. The "glass" naming is preserved so existing call-sites
/// compile without changes — the visual language just shifted from
/// frosted-blur to clean solid cards that suit the minimal-clean
/// aesthetic.
///
/// [GlassCard] adds an optional tap target (ripple) on top, same
/// as before.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    // blurSigma kept as a param so call-sites don't break; ignored now.
    this.blurSigma = 0,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color fill = backgroundColor ??
        (dark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final Color stroke =
        borderColor ?? (dark ? AppColors.borderDark : AppColors.borderLight);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: stroke, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Solid card with optional tap target.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.borderRadius = 12,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color fill = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color stroke = dark ? AppColors.borderDark : AppColors.borderLight;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: margin,
      child: Material(
        color: fill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
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
