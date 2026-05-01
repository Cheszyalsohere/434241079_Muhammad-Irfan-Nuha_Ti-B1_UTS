/// Single source of truth for the "Tentang Aplikasi" dialog.
///
/// Used from the AppBar PopupMenuButton on every main screen and from
/// the Settings screen's Tentang section.
library;

import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';

/// Show the standard "Tentang Aplikasi" alert dialog: app icon, name,
/// version, description, developer credit, university affiliation, and
/// a single "Tutup" close button.
Future<void> showAboutAppDialog(BuildContext context) async {
  final ThemeData theme = Theme.of(context);
  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.confirmation_num_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'v${AppConstants.appVersion}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Sistem tiket IT helpdesk untuk manajemen keluhan dan '
              'penanganan masalah teknis.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _LabelValue(label: 'Developer', value: 'Irfan Nuha'),
            const SizedBox(height: 6),
            _LabelValue(label: 'NIM', value: '434241079'),
            const SizedBox(height: 6),
            _LabelValue(
              label: 'Program Studi',
              value: 'D4 Teknik Informatika',
            ),
            const SizedBox(height: 6),
            _LabelValue(
              label: 'Universitas',
              value: 'Universitas Airlangga',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
