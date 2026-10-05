import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Big number over a label. Tappable when [onTap] is set. The caller picks
/// [trendColor] because up can be good or bad depending on the stat.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.isSelected = false,
    this.trendLabel,
    this.trendColor,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? trendLabel;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color);
    final card = Card(
      color: isSelected ? color.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (trendLabel == null)
              Text(value, style: valueStyle)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: valueStyle.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trendLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trendColor ?? AppColors.otherText,
                    ),
                  ),
                ],
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
