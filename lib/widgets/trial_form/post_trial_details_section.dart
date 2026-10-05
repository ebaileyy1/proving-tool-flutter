import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/trial_form/trial_form_controller.dart';
import 'package:proving_tool/widgets/trial_form/trial_text_field.dart';

/// Shown once a trial is Completed or Failed, plus an optional evidence slot.
class PostTrialDetailsSection extends StatelessWidget {
  const PostTrialDetailsSection({super.key, required this.controller, this.evidenceSection});

  final TrialFormController controller;
  final Widget? evidenceSection;

  @override
  Widget build(BuildContext context) {
    final isCompleted = controller.status == 'Completed';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isCompleted ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isCompleted ? AppColors.success : AppColors.error),
          ),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                color: isCompleted ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trial marked as ${controller.status} - fill in post-trial details below',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TrialTextField(controller.howTrialWent, 'How the Trial Went', maxLines: 4),
        const SizedBox(height: 16),
        TrialTextField(controller.actualOutcome, 'Actual Outcome', maxLines: 3),
        const SizedBox(height: 16),
        TrialTextField(
          controller.evidenceSummary,
          'Evidence Summary',
          hint: 'Summarise the evidence collected',
          maxLines: 3,
        ),
        if (evidenceSection != null) ...[const SizedBox(height: 16), evidenceSection!],
      ],
    );
  }
}
