/// Bottom sheet that lets the user choose an avatar source — camera,
/// gallery, or (when an avatar already exists) remove the current one.
///
/// Returns an [AvatarPickerAction] when the user taps a row, or `null`
/// when the sheet is dismissed without a choice. The screen owns the
/// actual permission request / picker / cropper / upload flow — this
/// widget is purely UI.
library;

import 'package:flutter/material.dart';

enum AvatarPickerAction { camera, gallery, remove }

/// Show the picker. Returns the user's choice, or `null` if dismissed.
Future<AvatarPickerAction?> showAvatarPickerBottomSheet(
  BuildContext context, {
  required bool hasAvatar,
}) {
  return showModalBottomSheet<AvatarPickerAction>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil dari Kamera'),
            onTap: () =>
                Navigator.of(ctx).pop(AvatarPickerAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () =>
                Navigator.of(ctx).pop(AvatarPickerAction.gallery),
          ),
          if (hasAvatar)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'Hapus Foto',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () =>
                  Navigator.of(ctx).pop(AvatarPickerAction.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
