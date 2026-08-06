import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// A big-number-over-label stat tile, used for the Dashboard's trial
/// counts and the Admin screen's user counts. Optionally tappable with a
/// selected-highlight state (Dashboard uses this to filter by status;
/// Admin's are purely informational and just omit [onTap]).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.isSelected = false,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: isSelected ? color.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.otherText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return Expanded(
      child: onTap == null ? card : GestureDetector(onTap: onTap, child: card),
    );
  }
}
