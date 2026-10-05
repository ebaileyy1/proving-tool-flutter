import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/stat_card.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class StatCardsRow extends StatelessWidget {
  final int total;
  final Map<String, int> statusCounts;
  final String? selectedStatus;
  final String? totalTrend;
  final String? completedTrend;
  final String? failedTrend;
  final ValueChanged<String> onStatusTap;

  const StatCardsRow({
    super.key,
    required this.total,
    required this.statusCounts,
    required this.selectedStatus,
    required this.totalTrend,
    required this.completedTrend,
    required this.failedTrend,
    required this.onStatusTap,
  });

  Color? _trendColorFor(String? label, {required bool higherIsBetter}) {
    if (label == null) return null;
    if (label == '0%') return AppColors.otherText;
    final isIncrease = label.startsWith('+');
    if (!higherIsBetter) {
      return isIncrease ? AppColors.error : AppColors.success;
    }
    return isIncrease ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatCard(
          label: 'Total',
          value: total.toString(),
          color: Colors.blueGrey,
          trendLabel: totalTrend,
          trendColor: _trendColorFor(totalTrend, higherIsBetter: true),
        ),
        const SizedBox(width: 8),
        for (final status in const ['Completed', 'In Progress', 'Failed', 'Pending']) ...[
          StatCard(
            label: status,
            value: statusCounts[status].toString(),
            color: kStatusColors[status]!,
            isSelected: selectedStatus == status,
            onTap: () => onStatusTap(status),
            trendLabel: status == 'Completed'
                ? completedTrend
                : status == 'Failed'
                ? failedTrend
                : null,
            trendColor: status == 'Completed'
                ? _trendColorFor(completedTrend, higherIsBetter: true)
                : status == 'Failed'
                ? _trendColorFor(failedTrend, higherIsBetter: false)
                : null,
          ),
          if (status != 'Pending') const SizedBox(width: 8),
        ],
      ],
    );
  }
}
