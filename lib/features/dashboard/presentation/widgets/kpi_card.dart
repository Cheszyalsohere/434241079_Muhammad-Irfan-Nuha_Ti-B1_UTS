/// Single KPI card — large mono value + label, with a thin coloured
/// accent rule on the left edge for at-a-glance status coding.
///
/// Minimal-clean: solid surface, hairline border, no blur. The number is
/// set in JetBrains Mono (the app's "data" voice); the accent colour is
/// reserved for a slim left bar + tiny dot rather than a filled icon
/// chip, keeping the card quiet.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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

  final String value;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(12);
    final Color fill =
        dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color stroke =
        dark ? AppColors.borderDark : AppColors.borderLight;

    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header row: icon (muted) + tappable affordance.
          Row(
            children: <Widget>[
              Icon(
                icon,
                size: 17,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_outward,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // The number — big, mono, tight.
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.monoLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: value.length > 4 ? 24 : 30,
            ),
          ),
          const SizedBox(height: 6),
          // Accent dot + label.
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Left accent rule painted via a clipped border layer.
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: stroke),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accent.withValues(alpha: 0.85)),
            ),
            content,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }
    return card;
  }
}
