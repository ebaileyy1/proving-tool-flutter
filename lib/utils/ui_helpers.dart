import 'package:flutter/material.dart';

void showMessage(BuildContext context, String text, {Duration? duration}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: duration ?? const Duration(milliseconds: 4000)),
  );
}
