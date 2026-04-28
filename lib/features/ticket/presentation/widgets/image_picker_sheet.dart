/// Reusable attachment picker: shows a bottom sheet with Camera /
/// Gallery options, then runs the selected source through
/// `image_picker` and `image_cropper` (square crop) and returns the
/// compressed JPEG bytes.
///
/// Callers receive `(bytes, fileName)` or `null` if the user cancels
/// at any step. Size is enforced here — files above
/// [AppConstants.maxAttachmentBytes] return a [ValidationException].
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

/// Result returned by [pickAttachment].
class AttachmentResult {
  const AttachmentResult({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
}

/// Opens the source-selection sheet and runs the picker pipeline.
/// Returns `null` if the user cancels or the sheet is dismissed.
Future<AttachmentResult?> pickAttachment(BuildContext context) async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Ambil Foto'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final ImagePicker picker = ImagePicker();
  final XFile? raw = await picker.pickImage(
    source: source,
    imageQuality: 85,
    maxWidth: 1920,
    maxHeight: 1920,
  );
  if (raw == null) return null;

  // Optional crop — user can skip via the picker's "Done" without
  // changing the crop rect. On failure we fall back to the raw file.
  // image_cropper has limited / no web support, so we skip cropping
  // entirely on web and upload the raw picked image.
  CroppedFile? cropped;
  if (!kIsWeb) {
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: raw.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Potong Gambar',
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(title: 'Potong Gambar'),
        ],
      );
    } catch (_) {
      cropped = null;
    }
  }

  // On web, `raw.path` is a blob URL — we read bytes via the XFile
  // directly rather than re-wrapping with `XFile(path)`, which would
  // try to construct a file from a non-filesystem path.
  final Uint8List bytes = cropped != null
      ? await XFile(cropped.path).readAsBytes()
      : await raw.readAsBytes();

  if (bytes.lengthInBytes > AppConstants.maxAttachmentBytes) {
    throw ValidationException(
      'Ukuran gambar melebihi batas '
      '${(AppConstants.maxAttachmentBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
    );
  }

  // Keep the original extension when possible so content-type inference
  // in the datasource stays accurate.
  final String originalName =
      raw.name.isNotEmpty ? raw.name : 'attachment.jpg';
  return AttachmentResult(bytes: bytes, fileName: originalName);
}
