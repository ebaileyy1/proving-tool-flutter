import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/utils/dates.dart';

class TrialDates {
  static bool isNotYetResolved(Map<String, dynamic> trial) {
    final status = trial['status_of_trial']?.toString();
    return status == 'Pending' || status == 'In Progress';
  }

  static DateTime? _dateOnlyOf(Map<String, dynamic> trial, String key) {
    final date = DateTime.tryParse(trial[key]?.toString() ?? '');
    return date == null ? null : dateOnly(date);
  }

  static DateTime? startDateOnly(Map<String, dynamic> trial) => _dateOnlyOf(trial, 'date_of_start');

  static int compareByStartDate(TrialListItem a, TrialListItem b) {
    return startDateOnly(a.data)!.compareTo(startDateOnly(b.data)!);
  }

  // Completion date only, no fallback to start date, so a trial without one
  // never shows as due.
  static DateTime? dueDateOnly(Map<String, dynamic> trial) =>
      _dateOnlyOf(trial, 'date_of_completion');

  static int compareByDueDate(TrialListItem a, TrialListItem b) {
    return dueDateOnly(a.data)!.compareTo(dueDateOnly(b.data)!);
  }

  static List<TrialListItem> dueItems(List<TrialListItem> allItems) {
    final todayDate = dateOnly(DateTime.now());
    final items = allItems.where((item) {
      if (!isNotYetResolved(item.data)) return false;
      final date = dueDateOnly(item.data);
      return date != null && !date.isAfter(todayDate);
    }).toList();
    items.sort(compareByDueDate);
    return items;
  }

  static List<TrialListItem> upcomingItems(List<TrialListItem> allItems) {
    final todayDate = dateOnly(DateTime.now());
    final windowEnd = todayDate.add(const Duration(days: 7));
    final items = allItems.where((item) {
      if (!isNotYetResolved(item.data)) return false;
      final date = startDateOnly(item.data);
      return date != null && date.isAfter(todayDate) && !date.isAfter(windowEnd);
    }).toList();
    items.sort(compareByStartDate);
    return items;
  }

  static int overdueCount(List<TrialListItem> dueItems) {
    final todayDate = dateOnly(DateTime.now());
    return dueItems.where((item) {
      final date = dueDateOnly(item.data);
      return date != null && date.isBefore(todayDate);
    }).length;
  }

  static List<String> upcomingTerminals(List<TrialListItem> upcomingItems) {
    final terminals = upcomingItems
        .map((item) => item.data['terminal_of_trial']?.toString())
        .whereType<String>()
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    terminals.sort();
    return terminals;
  }
}
