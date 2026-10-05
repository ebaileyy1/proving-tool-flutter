import 'package:flutter/material.dart';
import 'package:proving_tool/screens/dashboard/widgets/trial_dates.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/section_header.dart';

class UpcomingSection extends StatelessWidget {
  final List<TrialListItem> due;
  final List<TrialListItem> upcoming;
  final ValueChanged<TrialListItem> onOpen;
  final ValueChanged<TrialListItem> onAddOutcome;

  const UpcomingSection({
    super.key,
    required this.due,
    required this.upcoming,
    required this.onOpen,
    required this.onAddOutcome,
  });

  @override
  Widget build(BuildContext context) {
    if (due.isEmpty && upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (due.isNotEmpty) ...[
          SectionCard(
            children: [
              const SectionHeader('Today'),
              const SizedBox(height: 12),
              for (final item in due)
                DueTrialTile(
                  item: item,
                  onOpen: () => onOpen(item),
                  onAddOutcome: () => onAddOutcome(item),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          SectionCard(
            children: [
              const SectionHeader('This Week'),
              const SizedBox(height: 12),
              for (final item in upcoming)
                UpcomingTrialTile(item: item, onOpen: () => onOpen(item)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class DueTrialTile extends StatelessWidget {
  final TrialListItem item;
  final VoidCallback onOpen;
  final VoidCallback onAddOutcome;

  const DueTrialTile({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onAddOutcome,
  });

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = TrialDates.dueDateOnly(item.data);
    final isOverdue = date != null && date.isBefore(dateOnly(DateTime.now()));

    return _TileShell(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.data['fullname']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tag(
                      isOverdue ? 'Overdue' : 'Today',
                      isOverdue ? AppColors.error : AppColors.lightNavy,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.data['type_of_trial'] ?? ''} · ${item.data['terminal_of_trial'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.otherText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onAddOutcome, child: const Text('Add Outcome')),
        ],
      ),
    );
  }
}

class UpcomingTrialTile extends StatelessWidget {
  final TrialListItem item;
  final VoidCallback onOpen;

  const UpcomingTrialTile({super.key, required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final date = TrialDates.startDateOnly(item.data);
    final dateLabel = date == null ? '' : '${date.day}/${date.month}';

    return _TileShell(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.data['fullname']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.navy),
            ),
          ),
          const SizedBox(width: 8),
          Text(dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.otherText)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.otherText),
        ],
      ),
    );
  }
}

class _TileShell extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsets padding;
  final Widget child;

  const _TileShell({required this.onTap, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}
