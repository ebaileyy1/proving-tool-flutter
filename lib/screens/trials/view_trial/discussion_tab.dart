import 'package:flutter/material.dart';
import 'package:proving_tool/screens/trials/view_trial/trial_tab_scroll.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/section_card.dart';

// Typed text and open reply boxes live with the screen so they survive tab
// switches and reloads.
class DiscussionDrafts {
  final observationController = TextEditingController();
  final Map<int, bool> showReplyBox = {};
  final Map<int, TextEditingController> replyControllers = {};

  void dispose() {
    observationController.dispose();
    for (final c in replyControllers.values) {
      c.dispose();
    }
  }
}

class DiscussionTab extends StatelessWidget {
  final bool isPendingLocal;
  final List<Map<String, dynamic>> observations;
  final Map<int, List<Map<String, dynamic>>> replies;
  final DiscussionDrafts drafts;
  final VoidCallback onAddObservation;
  final void Function(int observationId) onAddReply;
  final void Function(int observationId) onToggleReply;

  const DiscussionTab({
    super.key,
    required this.isPendingLocal,
    required this.observations,
    required this.replies,
    required this.drafts,
    required this.onAddObservation,
    required this.onAddReply,
    required this.onToggleReply,
  });

  // Icon, username and date shared by an observation and its replies.
  List<Widget> _byline(IconData icon, double iconSize, Map<String, dynamic> m) {
    return [
      Icon(icon, size: iconSize, color: AppColors.otherText),
      const SizedBox(width: 4),
      Text(
        m['username']?.toString() ?? 'Unknown',
        style: const TextStyle(
          color: AppColors.lightNavy,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        m['created_at']?.toString().split('T')[0] ?? '',
        style: const TextStyle(color: AppColors.otherText, fontSize: 12),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isPendingLocal) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.cloud_off, size: 40, color: AppColors.otherText),
              SizedBox(height: 12),
              Text(
                "Discussion will be available once this trial has synced.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.otherText),
              ),
            ],
          ),
        ),
      );
    }

    return TrialTabScroll(
      child: SectionCard(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: drafts.observationController,
                  decoration: const InputDecoration(labelText: 'Add an observation'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: onAddObservation, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          observations.isEmpty
              ? const Text('No observations yet.', style: TextStyle(color: AppColors.otherText))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: observations.length,
                  itemBuilder: (context, index) {
                    final obs = observations[index];
                    final obsId = (obs['id'] as num).toInt();
                    final obsReplies = replies[obsId] ?? [];
                    final showReply = drafts.showReplyBox[obsId] ?? false;

                    if (!drafts.replyControllers.containsKey(obsId)) {
                      drafts.replyControllers[obsId] = TextEditingController();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  obs['content']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ..._byline(Icons.person, 12, obs),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => onToggleReply(obsId),
                                      icon: const Icon(Icons.reply, size: 14),
                                      label: Text(
                                        showReply ? 'Cancel' : 'Reply',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (obsReplies.isNotEmpty)
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.border)),
                                color: AppColors.subBackground,
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: obsReplies.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, rIndex) {
                                  final reply = obsReplies[rIndex];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: _byline(
                                            Icons.subdirectory_arrow_right,
                                            14,
                                            reply,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 18),
                                          child: Text(
                                            reply['content']?.toString() ?? '',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          if (showReply)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.border)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: drafts.replyControllers[obsId],
                                      decoration: const InputDecoration(
                                        labelText: 'Write a reply...',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => onAddReply(obsId),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Send'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
