import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/section_card.dart';

class TypePieChart extends StatelessWidget {
  final Map<String, int> counts;
  final Map<String, Color> colors;
  final String? selected;
  final bool hasData;
  final ValueChanged<String?> onSelect;

  const TypePieChart({
    super.key,
    required this.counts,
    required this.colors,
    required this.selected,
    required this.hasData,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      children: [
        const Text('By Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Tap a slice to filter',
          style: TextStyle(fontSize: 12, color: AppColors.otherText),
        ),
        const SizedBox(height: 12),
        !hasData
            ? const Text('No data')
            : SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response?.touchedSection != null) {
                          final index = response!.touchedSection!.touchedSectionIndex;
                          final types = counts.keys.toList();
                          if (index >= 0 && index < types.length) {
                            final tapped = types[index];
                            onSelect(selected == tapped ? null : tapped);
                          }
                        }
                      },
                    ),
                    sections: counts.entries.map((entry) {
                      final type = entry.key;
                      final count = entry.value;
                      final isSelected = selected == type;
                      final color = colors[type] ?? AppColors.otherText;
                      return PieChartSectionData(
                        value: count.toDouble(),
                        title: count.toString(),
                        color: color.withValues(alpha: isSelected ? 1.0 : 0.7),
                        radius: isSelected ? 70 : 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                  ),
                ),
              ),
        const SizedBox(height: 8),
        ...counts.entries.map(
          (entry) => GestureDetector(
            onTap: () => onSelect(selected == entry.key ? null : entry.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[entry.key] ?? AppColors.otherText,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: selected == entry.key ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
