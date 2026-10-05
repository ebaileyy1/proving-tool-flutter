import 'package:flutter/material.dart';
import 'package:proving_tool/widgets/empty_state.dart';

/// Shown instead of a spinner on online-only screens when there's no connection.
class OfflineState extends StatelessWidget {
  const OfflineState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: "You're offline",
      message: 'This screen needs an internet connection.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    );
  }
}
