import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Cancel / confirm dialog; resolves to true only when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: destructive ? const TextStyle(color: AppColors.error) : null,
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
