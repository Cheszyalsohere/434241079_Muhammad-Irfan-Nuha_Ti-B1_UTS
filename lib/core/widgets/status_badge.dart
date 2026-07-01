/// Compact badge rendering ticket status or priority.
///
/// Minimal-clean styling: a small coloured dot + label on a faint tinted
/// fill with a 6px radius. Colour tokens from [AppColors], Indonesian
/// labels from [AppLabels].
library;

import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BadgeKind { status, priority }

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.value, required this.kind, super.key});

  /// Status: `open` | `assigned` | `in_progress` | `closed`.
  /// Priority: `low` | `medium` | `high` | `urgent`.
  final String value;
  final BadgeKind kind;

  Color _color() => switch (kind) {
        BadgeKind.status => AppColors.statusColor(value),
        BadgeKind.priority => AppColors.priorityColor(value),
      };

  String _label() => switch (kind) {
        BadgeKind.status => AppLabels.status[value] ?? value,
        BadgeKind.priority => AppLabels.priority[value] ?? value,
      };

  @override
  Widget build(BuildContext context) {
    final Color color = _color();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label(),
            style: AppTextStyles.labelSmall.copyWith(
              color: dark ? color : _darken(color),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Slightly darken the token so label text stays legible on the faint
  /// tinted fill in light mode.
  static Color _darken(Color c) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }
}
