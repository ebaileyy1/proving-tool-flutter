import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class StatusBarChart extends StatelessWidget {
  final Map<String, int> counts;
  final String? selected;
  final bool hasData;
  final double maxY;
  final double yAxisInterval;
  final ValueChanged<String?> onSelect;

  const StatusBarChart({
    super.key,
    required this.counts,
    required this.selected,
    required this.hasData,
    required this.maxY,
    required this.yAxisInterval,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final statusKeys = counts.keys.toList();
    return SectionCard(
      children: [
        Row(
          children: [
            const Text(
              'Trials by Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (selected != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(selected!),
                onDeleted: () => onSelect(null),
                backgroundColor: kStatusColors[selected]?.withValues(alpha: 0.2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap a bar to filter trials',
          style: TextStyle(fontSize: 12, color: AppColors.otherText),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: !hasData
              ? const Center(child: Text('No data'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response?.spot != null) {
                          final index = response!.spot!.touchedBarGroupIndex;
                          if (index >= 0 && index < statusKeys.length) {
                            final tapped = statusKeys[index];
                            onSelect(selected == tapped ? null : tapped);
                          }
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          // Needs a fixed interval, otherwise fl_chart picks fractional steps and the
                          // int labels repeat (0, 0, 1, 1...).
                          interval: yAxisInterval,
                          getTitlesWidget: (value, meta) =>
                              Text(value.toInt().toString(), style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= statusKeys.length) {
                              return const Text('');
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                statusKeys[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: counts.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final status = entry.value.key;
                      final count = entry.value.value;
                      final isSelected = selected == status;
                      final color = colorForStatus(status);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: count.toDouble(),
                            color: color.withValues(alpha: isSelected ? 1.0 : 0.7),
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: isSelected,
                              toY: maxY,
                              color: color.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
