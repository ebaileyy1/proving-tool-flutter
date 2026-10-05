import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

class PendingSyncBanner extends StatelessWidget {
  const PendingSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightNavy.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: AppColors.lightNavy)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: AppColors.lightNavy),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "This trial hasn't synced yet - observations, PDF export and downloads will be available once it's online.",
              style: TextStyle(fontSize: 12, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class NeedsOutcomeBanner extends StatelessWidget {
  final VoidCallback onAddOutcome;

  const NeedsOutcomeBanner({super.key, required this.onAddOutcome});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: AppColors.warning)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "This trial's date has arrived - add the outcome when you're ready.",
              style: TextStyle(fontSize: 12, color: AppColors.navy),
            ),
          ),
          TextButton(onPressed: onAddOutcome, child: const Text('Add Outcome')),
        ],
      ),
    );
  }
}
