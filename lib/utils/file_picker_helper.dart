import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Take a photo or pick a file; both come back as a [PlatformFile].
Future<PlatformFile?> pickOrCaptureFile(BuildContext context, {bool allowMultiple = false}) async {
  final source = await _askSource(context, 'Choose File');
  switch (source) {
    case _PickSource.camera:
      return _captureFromCamera();
    case _PickSource.file:
      return (await _pickFiles(allowMultiple)).firstOrNull;
    case null:
      return null;
  }
}

/// Multi-file [pickOrCaptureFile]; the camera still returns one photo.
Future<List<PlatformFile>> pickOrCaptureFiles(BuildContext context) async {
  final source = await _askSource(context, 'Choose Files');
  switch (source) {
    case _PickSource.camera:
      final file = await _captureFromCamera();
      return file == null ? [] : [file];
    case _PickSource.file:
      return _pickFiles(true);
    case null:
      return [];
  }
}

Future<_PickSource?> _askSource(BuildContext context, String fileLabel) {
  return showModalBottomSheet<_PickSource>(
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
            title: Text(fileLabel),
            onTap: () => Navigator.of(context).pop(_PickSource.file),
          ),
        ],
      ),
    ),
  );
}

Future<List<PlatformFile>> _pickFiles(bool allowMultiple) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: allowMultiple,
    type: FileType.any,
    withData: true,
  );
  return result?.files ?? [];
}

Future<PlatformFile?> _captureFromCamera() async {
  final photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
  if (photo == null) return null;
  final bytes = await photo.readAsBytes();
  return PlatformFile(name: photo.name, size: bytes.length, bytes: bytes);
}

enum _PickSource { camera, file }
