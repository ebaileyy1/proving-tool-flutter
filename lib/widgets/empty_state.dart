import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Centered icon, title and message used for empty, denied and offline states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.textAlign,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final TextAlign? textAlign;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.otherText),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: textAlign,
            style: const TextStyle(color: AppColors.otherText),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
