/// Primary button — solid ink (monochrome) or outlined variant.
///
/// Full-width by default; `outlined: true` renders a hairline-bordered
/// secondary action. Styling comes from the theme; this widget only
/// arranges the icon + label + loading spinner.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool disabled = onPressed == null || isLoading;

    final Color spinnerColor =
        outlined ? scheme.onSurface : AppColors.onInkButton(dark);

    final Widget content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final Widget button = outlined
        ? OutlinedButton(
            onPressed: disabled ? null : onPressed,
            child: content,
          )
        : FilledButton(
            onPressed: disabled ? null : onPressed,
            child: content,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
