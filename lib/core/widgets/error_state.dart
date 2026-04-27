/// Reusable error panel — error icon + message + "Coba Lagi" button.
///
/// Use whenever an `AsyncValue` resolves to `error`. Keep messages
/// short and Indonesian. The optional [details] line is shown smaller
/// underneath, useful for surfacing the raw `Failure.message` while
/// keeping the headline friendly.
library;

import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    super.key,
  });

  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (details != null && details!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
