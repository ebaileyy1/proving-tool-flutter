import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Bold title plus divider above a content section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        const Divider(color: AppColors.border),
      ],
    );
  }
}
