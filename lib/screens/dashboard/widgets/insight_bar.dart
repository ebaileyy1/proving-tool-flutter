import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

class InsightChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color fg;
  final Color? bg;

  const InsightChip({super.key, required this.icon, required this.text, required this.fg, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg ?? fg.withValues(alpha: 0.08),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

class InsightBar extends StatelessWidget {
  final int dueCount;
  final int overdueCount;
  final double? currentRate;
  final double? previousRate;
  final int weekCount;
  final List<String> weekTerminals;

  const InsightBar({
    super.key,
    required this.dueCount,
    required this.overdueCount,
    required this.currentRate,
    required this.previousRate,
    required this.weekCount,
    required this.weekTerminals,
  });

  @override
  Widget build(BuildContext context) {
    final currentRate = this.currentRate;
    final previousRate = this.previousRate;
    final dueText = '$dueCount trial${dueCount == 1 ? '' : 's'} need an outcome';
    final outstandingChip = dueCount == 0
        ? InsightChip(
            icon: Icons.check_circle_outline,
            text: 'No trials waiting on an outcome',
            fg: AppColors.success,
          )
        : InsightChip(
            icon: Icons.warning_amber_rounded,
            text: overdueCount > 0 ? '$dueText - $overdueCount overdue' : '$dueText today',
            fg: AppColors.warning,
          );

    Widget? completionChip;
    if (currentRate != null && previousRate != null) {
      final delta = currentRate - previousRate;
      final improving = delta > 0.5;
      final declining = delta < -0.5;
      final color = improving
          ? AppColors.success
          : (declining ? AppColors.error : AppColors.otherText);
      completionChip = InsightChip(
        icon: improving
            ? Icons.trending_up
            : (declining ? Icons.trending_down : Icons.trending_flat),
        text: improving
            ? 'Completion rate up ${delta.abs().round()}% this month'
            : declining
            ? 'Completion rate down ${delta.abs().round()}% this month'
            : 'Completion rate steady this month',
        fg: color,
      );
    } else if (currentRate != null) {
      completionChip = InsightChip(
        icon: Icons.trending_up,
        text: 'Completion rate ${currentRate.round()}% this month',
        fg: AppColors.lightNavy,
      );
    }

    final weekChip = weekCount == 0
        ? InsightChip(
            icon: Icons.event_available,
            text: 'Nothing scheduled in the next 7 days',
            fg: AppColors.otherText,
            bg: AppColors.subBackground,
          )
        : InsightChip(
            icon: Icons.calendar_today,
            text:
                '$weekCount trial${weekCount == 1 ? '' : 's'} this week'
                '${weekTerminals.isEmpty ? '' : ' - ${weekTerminals.take(4).join(', ')}'}',
            fg: AppColors.lightNavy,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [outstandingChip, ?completionChip, weekChip],
      ),
    );
  }
}
