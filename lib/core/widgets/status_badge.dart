/// Pill-shaped badge rendering ticket status or priority with color
/// tokens from [AppColors] and Indonesian labels from [AppLabels].
library;

import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BadgeKind { status, priority }

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.value, required this.kind, super.key});

  /// Status: `open` | `in_progress` | `resolved` | `closed`.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _label(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
