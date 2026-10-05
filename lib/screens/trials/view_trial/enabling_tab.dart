import 'package:flutter/material.dart';
import 'package:proving_tool/screens/trials/view_trial/trial_tab_scroll.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/enabling_checklist_widgets.dart';

class EnablingTab extends StatelessWidget {
  final bool Function(String field) isChecked;
  final Map<String, String> reasons;
  final bool isComplete;
  final bool isPendingLocal;
  final void Function(String field, bool value) onToggle;
  final void Function(String field, String value) onSetReason;

  const EnablingTab({
    super.key,
    required this.isChecked,
    required this.reasons,
    required this.isComplete,
    required this.isPendingLocal,
    required this.onToggle,
    required this.onSetReason,
  });

  @override
  Widget build(BuildContext context) {
    return TrialTabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPendingLocal) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightNavy),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: AppColors.lightNavy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This checklist is read-only until the trial finishes syncing.",
                      style: TextStyle(fontSize: 12, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          EnablingStatusBanner(
            complete: isComplete,
            incompleteText:
                'Proving Scripts needs to be checked off (or given a reason) before Status can move to In Progress/Completed. Permits/Safety/Site Access below are for tracking - nothing there blocks starting.',
          ),
          const SizedBox(height: 16),
          EnablingChecklist(
            provingScriptsLabel: 'Proving Scripts ready',
            isChecked: isChecked,
            reason: (field) => reasons[field] ?? '',
            onToggle: isPendingLocal ? null : onToggle,
            onEditReason: isPendingLocal ? null : onSetReason,
            titleColor: AppColors.navy,
          ),
        ],
      ),
    );
  }
}
