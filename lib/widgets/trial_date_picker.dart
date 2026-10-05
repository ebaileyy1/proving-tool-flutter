import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';

/// Mon..Sun header row shared by the calendar and the date picker.
class WeekdayRow extends StatelessWidget {
  const WeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in weekdayLabels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.otherText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Month-grid picker for Start Date. Days before [minDate] are disabled and each
/// day shows how many trials are already booked.
Future<DateTime?> showTrialDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime minDate,
  required DateTime maxDate,
  required Map<DateTime, int> countsByDay,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _TrialDatePickerDialog(
      initialDate: initialDate,
      minDate: minDate,
      maxDate: maxDate,
      countsByDay: countsByDay,
    ),
  );
}

class _TrialDatePickerDialog extends StatefulWidget {
  const _TrialDatePickerDialog({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.countsByDay,
  });

  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final Map<DateTime, int> countsByDay;

  @override
  State<_TrialDatePickerDialog> createState() => _TrialDatePickerDialogState();
}

class _TrialDatePickerDialogState extends State<_TrialDatePickerDialog> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  List<DateTime?> get _gridDays {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = (first.weekday - 1) % 7;
    return [
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(_visibleMonth.year, _visibleMonth.month, d),
    ];
  }

  bool get _canGoPrev {
    final prevMonthEnd = DateTime(_visibleMonth.year, _visibleMonth.month, 0);
    return !prevMonthEnd.isBefore(dateOnly(widget.minDate));
  }

  bool get _canGoNext {
    final nextMonthStart = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    return !nextMonthStart.isAfter(widget.maxDate);
  }

  void _shiftMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final minDate = dateOnly(widget.minDate);
    final maxDate = dateOnly(widget.maxDate);

    return Dialog(
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Start Date',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
                ),
                Text(
                  '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _canGoNext ? () => _shiftMonth(1) : null,
                ),
              ],
            ),
            const WeekdayRow(),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final day in _gridDays)
                  if (day == null) const SizedBox.shrink() else _dayCell(day, minDate, maxDate),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _legend(AppColors.subBackground, 'Blocked'),
                const SizedBox(width: 14),
                _legend(AppColors.warning, 'Booked'),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.otherText)),
      ],
    );
  }

  Widget _dayCell(DateTime day, DateTime minDate, DateTime maxDate) {
    final blocked = day.isBefore(minDate) || day.isAfter(maxDate);
    final count = widget.countsByDay[day] ?? 0;
    final isSelected = isSameDay(day, dateOnly(widget.initialDate));

    return InkWell(
      onTap: blocked ? null : () => Navigator.of(context).pop(day),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : (blocked ? AppColors.subBackground : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: blocked
                    ? AppColors.otherText.withValues(alpha: 0.4)
                    : (isSelected ? Colors.white : AppColors.navy),
              ),
            ),
            if (!blocked && count > 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
