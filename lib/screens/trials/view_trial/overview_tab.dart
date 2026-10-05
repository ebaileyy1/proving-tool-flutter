import 'package:flutter/material.dart';
import 'package:proving_tool/models/attendee.dart';
import 'package:proving_tool/screens/trials/view_trial/activity_feed.dart';
import 'package:proving_tool/screens/trials/view_trial/trial_tab_scroll.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/section_header.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> trial;
  final String status;
  final bool isPostTrial;
  final bool isPendingLocal;
  final List<Map<String, dynamic>> activity;
  final Map<String, String> usernamesById;
  final ValueChanged<bool> onPickDate;

  const OverviewTab({
    super.key,
    required this.trial,
    required this.status,
    required this.isPostTrial,
    required this.isPendingLocal,
    required this.activity,
    required this.usernamesById,
    required this.onPickDate,
  });

  String _text(String key) => trial[key]?.toString() ?? '';

  // A row per non-empty value, or [emptyText] when there are none.
  List<Widget> _detailRows(List<(String, String)> fields, String emptyText) {
    final rows = [
      for (final (label, value) in fields)
        if (value.isNotEmpty) DetailRow(label, value),
    ];
    if (rows.isNotEmpty) return rows;
    return [Text(emptyText, style: const TextStyle(color: AppColors.otherText, fontSize: 13))];
  }

  @override
  Widget build(BuildContext context) {
    final attendees = _text('attendees');
    final postColor = status == 'Completed' ? AppColors.success : AppColors.error;
    return TrialTabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            children: [
              SectionHeader('Trial Information'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: trial['status_of_trial']?.toString()),
                  MetaTag(icon: Icons.science_outlined, label: trial['type_of_trial']?.toString()),
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
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DateBlock(
                      Icons.event,
                      'Start Date',
                      trial['date_of_start']?.toString(),
                      onTap: isPendingLocal ? null : () => onPickDate(true),
                    ),
                  ),
                  Expanded(
                    child: DateBlock(
                      Icons.event_available,
                      'End Date',
                      trial['date_of_completion']?.toString(),
                      onTap: isPendingLocal ? null : () => onPickDate(false),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          SectionCard(
            children: [
              SectionHeader('Pre-Trial Details'),
              const SizedBox(height: 12),
              ..._detailRows([
                ('Description', _text('description_of_trial')),
                ('Expected Outcome', _text('expected_outcome')),
                ('Run Plan', _text('run_plan')),
                ('Attendees', attendees.isEmpty ? '' : formatAttendeesForDisplay(attendees)),
              ], 'No pre-trial details added yet.'),
            ],
          ),

          if (isPostTrial) ...[
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: postColor, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          status == 'Completed' ? Icons.check_circle : Icons.cancel,
                          color: postColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Post-Trial Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: postColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Divider(color: postColor.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    ..._detailRows([
                      ('How It Went', _text('how_trial_went')),
                      ('Actual Outcome', _text('actual_outcome')),
                      ('Evidence Summary', _text('evidence_summary')),
                    ], 'No post-trial details added yet. Edit the trial to add them.'),
                  ],
                ),
              ),
            ),
          ],

          if (activity.isNotEmpty) ...[
            const SizedBox(height: 16),
            ActivityFeed(activity, usernamesById),
          ],
        ],
      ),
    );
  }
}

class DateBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? rawValue;
  final VoidCallback? onTap;

  const DateBlock(this.icon, this.label, this.rawValue, {super.key, this.onTap});

  String? _relativeDayLabel(DateTime? date) {
    if (date == null) return null;
    final diff = dateOnly(date).difference(dateOnly(DateTime.now())).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return '${-diff} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(rawValue ?? '');
    final relative = _relativeDayLabel(date);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.subBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.lightNavy),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.otherText,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        date == null ? '-' : rawValue!.split('T').first,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      if (relative != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· $relative',
                          style: const TextStyle(fontSize: 12, color: AppColors.otherText),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit_outlined, size: 14, color: AppColors.otherText),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const DetailRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.otherText,
            ),
          ),
          const SizedBox(height: 2),
          Text(value ?? '-'),
        ],
      ),
    );
  }
}
