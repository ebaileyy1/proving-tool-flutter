import 'package:flutter/material.dart';
import 'package:proving_tool/screens/dashboard/widgets/status_bar_chart.dart';
import 'package:proving_tool/screens/dashboard/widgets/terminal_breakdown.dart';
import 'package:proving_tool/screens/dashboard/widgets/type_pie_chart.dart';

class ChartsRow extends StatelessWidget {
  final int total;
  final Map<String, int> statusCounts;
  final Map<String, int> typeCounts;
  final Map<String, int> terminalCounts;
  final Map<String, Color> typeColors;
  final String? selectedStatus;
  final String? selectedType;
  final ValueChanged<String?> onStatusSelect;
  final ValueChanged<String?> onTypeSelect;

  const ChartsRow({
    super.key,
    required this.total,
    required this.statusCounts,
    required this.typeCounts,
    required this.terminalCounts,
    required this.typeColors,
    required this.selectedStatus,
    required this.selectedType,
    required this.onStatusSelect,
    required this.onTypeSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = total > 0;
    final maxY = statusCounts.values.isEmpty
        ? 1.0
        : statusCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 1;
    final yAxisInterval = maxY <= 10 ? 1.0 : (maxY / 10).ceilToDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: StatusBarChart(
            counts: statusCounts,
            selected: selectedStatus,
            hasData: hasData,
            maxY: maxY,
            yAxisInterval: yAxisInterval,
            onSelect: onStatusSelect,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 1,
          child: Column(
            children: [
              TypePieChart(
                counts: typeCounts,
                colors: typeColors,
                selected: selectedType,
                hasData: hasData,
                onSelect: onTypeSelect,
              ),
              const SizedBox(height: 12),
              TerminalBreakdown(counts: terminalCounts, total: total),
            ],
          ),
        ),
      ],
    );
  }
}
