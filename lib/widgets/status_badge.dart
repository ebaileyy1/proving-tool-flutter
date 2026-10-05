import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Color per trial status, shared by the dashboard, detail screen and PDF.
const Map<String, Color> kStatusColors = {
  'Completed': AppColors.success,
  'In Progress': AppColors.lightNavy,
  'Pending': AppColors.warning,
  'Failed': AppColors.error,
};

Color colorForStatus(String? status) => kStatusColors[status] ?? AppColors.otherText;

/// Dot-and-label pill that [StatusBadge] and the sync queue badge build on.
class ColorPill extends StatelessWidget {
  const ColorPill({super.key, required this.label, required this.color, this.dense = false});

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dense ? 6 : 8,
            height: dense ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: dense ? 5 : 7),
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored pill for a trial's status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.dense = false});

  final String? status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ColorPill(
      label: status?.isNotEmpty == true ? status! : 'Unknown',
      color: colorForStatus(status),
      dense: dense,
    );
  }
}

/// Neutral icon + text pill for non-status metadata like type or terminal.
class MetaTag extends StatelessWidget {
  const MetaTag({super.key, required this.icon, required this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.subBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.otherText),
          const SizedBox(width: 5),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
