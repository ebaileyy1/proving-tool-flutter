import 'package:flutter/material.dart';
import 'package:proving_tool/widgets/trial_form/trial_form_controller.dart';
import 'package:proving_tool/widgets/trial_form/trial_text_field.dart';

/// Description, expected outcome and run plan, plus an optional drawings slot from Add.
class PreTrialDetailsSection extends StatelessWidget {
  const PreTrialDetailsSection({super.key, required this.controller, this.drawingsSection});

  final TrialFormController controller;
  final Widget? drawingsSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrialTextField(controller.description, 'Description', maxLines: 3),
        const SizedBox(height: 16),
        TrialTextField(controller.expectedOutcome, 'Expected Outcome', maxLines: 3),
        const SizedBox(height: 16),
        TrialTextField(controller.runPlan, 'Run Plan', maxLines: 4),
        if (drawingsSection != null) ...[const SizedBox(height: 16), drawingsSection!],
      ],
    );
  }
}
