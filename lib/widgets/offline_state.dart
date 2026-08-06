import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Shown instead of an indefinite spinner when a screen needs a network
/// call to load and there's no connection — used by screens (admin,
/// notifications) that aren't offline-capable themselves.
class OfflineState extends StatelessWidget {
  const OfflineState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: AppColors.otherText),
          const SizedBox(height: 16),
          const Text(
            "You're offline",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          const Text(
            'This screen needs an internet connection.',
            style: TextStyle(color: AppColors.otherText),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
