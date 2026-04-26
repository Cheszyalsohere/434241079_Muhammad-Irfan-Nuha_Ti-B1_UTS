/// Single KPI card — count + label + tinted icon chip + optional
/// subtitle (e.g. "rata-rata jam" for avg-resolution).
///
/// Built on top of [GlassContainer] so it inherits the frosted look
/// of the rest of the surface system. Tapping is optional — when
/// [onTap] is set, the card forwards taps via a `Material + InkWell`
/// painted above the blur, the same pattern [GlassCard] uses.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.onTap,
  });

  /// The big-number string. Strings (not int) so callers can format
  /// — `"3"`, `"12"`, `"4.5 jam"`, `"99+"` are all valid.
  final String value;

  /// Caption under the number.
  final String label;

  /// Optional secondary line below [label] (smaller, muted).
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(20);
    final bool dark = theme.brightness == Brightness.dark;

    final Widget content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Tinted icon chip — gives each card an immediate hue cue.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );

    // Tappable variant: ink ripple painted above the backdrop blur.
    if (onTap != null) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: dark
                ? AppColors.glassSurfaceDark
                : AppColors.glassSurfaceLight,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: dark
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorderLight,
                    width: 1,
                  ),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    // Static variant — plain glass surface.
    return GlassContainer(child: content);
  }
}
