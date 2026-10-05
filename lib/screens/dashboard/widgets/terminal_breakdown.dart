import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/section_card.dart';

class TerminalBreakdown extends StatelessWidget {
  final Map<String, int> counts;
  final int total;
  final String title;
  final Color barColor;
  final TextStyle? emptyStyle;

  const TerminalBreakdown({
    super.key,
    required this.counts,
    required this.total,
    this.title = 'By Terminal',
    this.barColor = Colors.blueGrey,
    this.emptyStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        total == 0
            ? Text('No data', style: emptyStyle)
            : Column(
                children: counts.entries.map((entry) {
                  final percent = total == 0 ? 0.0 : entry.value / total;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${entry.value} (${(percent * 100).toStringAsFixed(0)}%)'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: AppColors.subBackground,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
