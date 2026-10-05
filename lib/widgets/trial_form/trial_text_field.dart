import 'package:flutter/material.dart';

class TrialTextField extends StatelessWidget {
  const TrialTextField(
    this.controller,
    this.label, {
    super.key,
    this.hint,
    this.maxLines = 1,
    this.dense,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool? dense;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint, isDense: dense),
      maxLines: maxLines,
    );
  }
}
