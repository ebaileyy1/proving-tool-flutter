import 'package:flutter/material.dart';

class FilterOptions {
  final List<String> years;
  final List<String> months;
  final List<String> terminals;
  final List<String> subAreas;

  const FilterOptions({
    required this.years,
    required this.months,
    required this.terminals,
    required this.subAreas,
  });
}

class FilterSelection {
  final String? year;
  final String? month;
  final String? terminal;
  final String? subArea;

  const FilterSelection({
    required this.year,
    required this.month,
    required this.terminal,
    required this.subArea,
  });
}

class FiltersCard extends StatelessWidget {
  final FilterOptions options;
  final FilterSelection selection;
  final bool showClear;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<String?> onTerminalChanged;
  final ValueChanged<String?> onSubAreaChanged;
  final VoidCallback onClear;

  const FiltersCard({
    super.key,
    required this.options,
    required this.selection,
    required this.showClear,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onTerminalChanged,
    required this.onSubAreaChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilterDropdown(
                    label: 'Year',
                    value: selection.year,
                    options: options.years,
                    onChanged: onYearChanged,
                  ),
                  FilterDropdown(
                    label: 'Month',
                    value: selection.month,
                    options: options.months,
                    onChanged: onMonthChanged,
                  ),
                  FilterDropdown(
                    label: 'Terminal',
                    value: selection.terminal,
                    options: options.terminals,
                    onChanged: onTerminalChanged,
                  ),
                  FilterDropdown(
                    label: 'Sub-Area',
                    value: selection.subArea,
                    options: options.subAreas,
                    onChanged: onSubAreaChanged,
                    width: 170,
                    ellipsis: true,
                  ),
                  if (showClear)
                    TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear all'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final double width;
  final bool ellipsis;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 150,
    this.ellipsis = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value ?? 'All',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o, overflow: ellipsis ? TextOverflow.ellipsis : null),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
