import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/section_header.dart';

class ActivityFeed extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  final Map<String, String> usernamesById;

  const ActivityFeed(this.activity, this.usernamesById, {super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      children: [
        SectionHeader('Activity'),
        const SizedBox(height: 12),
        for (final entry in activity) ActivityRow(entry, usernamesById),
      ],
    );
  }
}

class ActivityRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Map<String, String> usernamesById;

  const ActivityRow(this.entry, this.usernamesById, {super.key});

  @override
  Widget build(BuildContext context) {
    final actionCompleted = entry['action_completed']?.toString() ?? 'Updated trial';
    final userId = entry['user_id']?.toString();
    final username = usernamesById[userId] ?? 'Someone';
    final loggedAt = DateTime.tryParse(entry['logged_at']?.toString() ?? '');
    final isCreate = actionCompleted.toLowerCase().startsWith('created');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCreate ? AppColors.success : AppColors.lightNavy,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.navy),
                    children: [
                      TextSpan(
                        text: username,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' - '),
                      TextSpan(
                        text: actionCompleted,
                        style: const TextStyle(color: AppColors.otherText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                if (loggedAt != null)
                  Text(
                    _formatActivityTime(loggedAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.otherText),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatActivityTime(DateTime at) {
    final local = at.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} at $h:$m';
  }
}
