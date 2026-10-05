import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/dashboard/widgets/trial_dates.dart';
import 'package:proving_tool/screens/trials/view_trial_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/status_badge.dart';
import 'package:proving_tool/widgets/trial_date_picker.dart';

/// Month-grid view of trials by start date.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final TrialRepository _repo;
  bool _repoInitialized = false;
  List<TrialListItem> _allItems = [];
  bool _isLoading = true;
  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDay = dateOnly(now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_repoInitialized) {
      _repoInitialized = true;
      _repo = AppServices.of(context).trialRepository;
      _allItems = _repo.trials.value;
      _repo.trials.addListener(_onTrialsChanged);
      _loadTrials();
    }
  }

  @override
  void dispose() {
    _repo.trials.removeListener(_onTrialsChanged);
    super.dispose();
  }

  void _onTrialsChanged() {
    if (mounted) setState(() => _allItems = _repo.trials.value);
  }

  Future<void> _loadTrials() async {
    setState(() => _isLoading = true);
    await _repo.refresh();
    if (mounted) setState(() => _isLoading = false);
  }

  Map<DateTime, List<TrialListItem>> get _itemsByDay {
    final map = <DateTime, List<TrialListItem>>{};
    for (final item in _allItems) {
      final key = TrialDates.startDateOnly(item.data);
      if (key == null) continue;
      map.putIfAbsent(key, () => []).add(item);
    }
    for (final list in map.values) {
      list.sort(
        (a, b) =>
            (a.data['fullname']?.toString() ?? '').compareTo(b.data['fullname']?.toString() ?? ''),
      );
    }
    return map;
  }

  List<DateTime?> get _gridDays {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // weekday is Mon=1..Sun=7 and the grid starts on Monday.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    return List.generate(totalCells, (i) {
      final dayNum = i - leadingBlanks + 1;
      if (dayNum < 1 || dayNum > daysInMonth) return null;
      return DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month, 1);
      _selectedDay = dateOnly(now);
    });
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            tooltip: 'Previous month',
          ),
          SizedBox(
            width: 190,
            child: Text(
              '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
            tooltip: 'Next month',
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _goToToday, child: const Text('Today')),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime? date, Map<DateTime, List<TrialListItem>> itemsByDay) {
    if (date == null) return const SizedBox.shrink();
    final dayItems = itemsByDay[date] ?? const <TrialListItem>[];
    final isToday = isSameDay(date, DateTime.now());
    final isSelected = _selectedDay != null && isSameDay(date, _selectedDay!);
    const maxShown = 3;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _selectedDay = date),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.10) : null,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 0.75,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? AppColors.navy : null,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.white : AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 3),
            ...dayItems.take(maxShown).map((item) {
              final color = colorForStatus(item.data['status_of_trial']?.toString());
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.data['fullname']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                ),
              );
            }),
            if (dayItems.length > maxShown)
              Text(
                '+${dayItems.length - maxShown} more',
                style: const TextStyle(fontSize: 9, color: AppColors.otherText),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dayDetailPanel(Map<DateTime, List<TrialListItem>> itemsByDay) {
    final day = _selectedDay;
    if (day == null) {
      return const Center(
        child: Text('Select a day to see its trials', style: TextStyle(color: AppColors.otherText)),
      );
    }
    final items = itemsByDay[day] ?? const <TrialListItem>[];
    const weekdayFull = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${weekdayFull[day.weekday - 1]}, ${day.day} ${monthNames[day.month - 1]} ${day.year}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        Text(
          items.isEmpty
              ? 'No trials scheduled'
              : '${items.length} trial${items.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: AppColors.otherText),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Expanded(
            child: Center(child: Icon(Icons.event_available, size: 40, color: AppColors.border)),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final trial = item.data;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final result = await Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => ViewTrialScreen(item: item)));
                    if (result == true) _loadTrials();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trial['fullname']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            StatusBadge(status: trial['status_of_trial']?.toString(), dense: true),
                            MetaTag(
                              icon: Icons.science_outlined,
                              label: trial['type_of_trial']?.toString(),
                            ),
                            MetaTag(
                              icon: Icons.location_on_outlined,
                              label: trial['terminal_of_trial']?.toString(),
                            ),
                            MetaTag(
                              icon: Icons.pin_drop_outlined,
                              label: trial['sub_area_of_trial']?.toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsByDay = _itemsByDay;
    final days = _gridDays;

    return Scaffold(
      appBar: AppHeader(
        title: 'Calendar',
        actions: [
          HeaderIconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTrials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final calendar = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _monthHeader(),
                      const WeekdayRow(),
                      const SizedBox(height: 6),
                      Expanded(
                        child: GridView.builder(
                          itemCount: days.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (context, index) => _dayCell(days[index], itemsByDay),
                        ),
                      ),
                    ],
                  );

                  final detail = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _dayDetailPanel(itemsByDay),
                    ),
                  );

                  if (constraints.maxWidth < 820) {
                    return Column(
                      children: [
                        Expanded(flex: 3, child: calendar),
                        const SizedBox(height: 16),
                        SizedBox(height: 260, child: detail),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: calendar),
                      const SizedBox(width: 16),
                      SizedBox(width: 320, child: detail),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
