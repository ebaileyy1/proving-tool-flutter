import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class TrialTrends {
  static int countInWindow(
    List<TrialListItem> allItems,
    DateTime start,
    DateTime end, {
    String? status,
  }) {
    return allItems.where((item) {
      final createdAt = DateTime.tryParse(item.data['created_at']?.toString() ?? '');
      if (createdAt == null) return false;
      if (createdAt.isBefore(start) || !createdAt.isBefore(end)) return false;
      if (status != null && item.data['status_of_trial'] != status) {
        return false;
      }
      return true;
    }).length;
  }

  // Null when nothing resolved in the window.
  static double? completionRateForWindow(
    List<TrialListItem> allItems,
    DateTime start,
    DateTime end,
  ) {
    return completionRate(
      countInWindow(allItems, start, end, status: 'Completed'),
      countInWindow(allItems, start, end, status: 'Failed'),
    );
  }

  // Null when nothing resolved.
  static double? completionRate(int completed, int failed) {
    final resolved = completed + failed;
    return resolved == 0 ? null : completed / resolved * 100;
  }

  static Map<String, int> countsBy(
    Iterable<Map<String, dynamic>> trials,
    String field,
    String fallback, [
    Map<String, int> initial = const {},
  ]) {
    final counts = {...initial};
    for (final trial in trials) {
      final key = trial[field]?.toString() ?? fallback;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> statusCounts(Iterable<Map<String, dynamic>> trials) => countsBy(
    trials,
    'status_of_trial',
    'Pending',
    {for (final status in kStatusColors.keys) status: 0},
  );

  static String? percentChangeLabel(int current, int previous) {
    if (previous == 0) return current == 0 ? null : '+new';
    final change = ((current - previous) / previous * 100).round();
    if (change == 0) return '0%';
    return '${change > 0 ? '+' : ''}$change%';
  }
}
