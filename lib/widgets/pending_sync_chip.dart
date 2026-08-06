import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Small badge shown on a trial list item that hasn't synced to Supabase
/// yet (or failed to).
class PendingSyncChip extends StatelessWidget {
  const PendingSyncChip({super.key, this.hasError = false});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final color = hasError ? AppColors.error : AppColors.lightNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.cloud_off,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            hasError ? 'Sync failed' : 'Pending sync',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
