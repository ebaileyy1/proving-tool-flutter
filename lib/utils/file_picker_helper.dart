import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Lets the user either take a photo or pick an existing file, returning
/// both as the same `PlatformFile` shape so callers don't need to care
/// which path was used. Used wherever a drawing/evidence file is attached.
Future<PlatformFile?> pickOrCaptureFile(
  BuildContext context, {
  bool allowMultiple = false,
}) async {
  final choice = await showModalBottomSheet<_PickSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera, color: AppColors.navy),
            title: const Text('Take Photo'),
            onTap: () => Navigator.of(context).pop(_PickSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open, color: AppColors.navy),
            title: const Text('Choose File'),
            onTap: () => Navigator.of(context).pop(_PickSource.file),
          ),
        ],
      ),
    ),
  );

  switch (choice) {
    case _PickSource.camera:
      return _captureFromCamera();
    case _PickSource.file:
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.any,
        withData: true,
      );
      return result?.files.firstOrNull;
    case null:
      return null;
  }
}

/// Multi-file variant of [pickOrCaptureFile] for screens that let the user
/// add several drawings/evidence files at once. Camera capture still
/// yields a single photo per tap (as it does on every camera app).
Future<List<PlatformFile>> pickOrCaptureFiles(BuildContext context) async {
  final choice = await showModalBottomSheet<_PickSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera, color: AppColors.navy),
            title: const Text('Take Photo'),
            onTap: () => Navigator.of(context).pop(_PickSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open, color: AppColors.navy),
            title: const Text('Choose Files'),
            onTap: () => Navigator.of(context).pop(_PickSource.file),
          ),
        ],
      ),
    ),
  );

  switch (choice) {
    case _PickSource.camera:
      final file = await _captureFromCamera();
      return file == null ? [] : [file];
    case _PickSource.file:
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      return result?.files ?? [];
    case null:
      return [];
  }
}

Future<PlatformFile?> _captureFromCamera() async {
  final photo = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 90,
  );
  if (photo == null) return null;
  final bytes = await photo.readAsBytes();
  return PlatformFile(name: photo.name, size: bytes.length, bytes: bytes);
}

enum _PickSource { camera, file }
