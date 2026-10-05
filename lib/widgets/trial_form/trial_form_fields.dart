import 'package:flutter/material.dart';
import 'package:proving_tool/widgets/section_header.dart';
import 'package:proving_tool/widgets/trial_form/attendees_section.dart';
import 'package:proving_tool/widgets/trial_form/enabling_section.dart';
import 'package:proving_tool/widgets/trial_form/post_trial_details_section.dart';
import 'package:proving_tool/widgets/trial_form/pre_trial_details_section.dart';
import 'package:proving_tool/widgets/trial_form/trial_form_controller.dart';
import 'package:proving_tool/widgets/trial_form/trial_info_section.dart';

/// The whole form as one page, used by EditTrialScreen. Add uses the sections
/// directly, one per wizard step.
class TrialFormFields extends StatefulWidget {
  const TrialFormFields({
    super.key,
    required this.controller,
    this.drawingsSection,
    this.evidenceSection,
    this.onViewCalendar,
  });

  final TrialFormController controller;
  final Widget? drawingsSection;
  final Widget? evidenceSection;
  final VoidCallback? onViewCalendar;

  @override
  State<TrialFormFields> createState() => _TrialFormFieldsState();
}

class _TrialFormFieldsState extends State<TrialFormFields> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Trial Information'),
        const SizedBox(height: 12),
        TrialInfoSection(
          controller: c,
          onChanged: () => setState(() {}),
          onViewCalendar: widget.onViewCalendar,
        ),

        const SizedBox(height: 24),
        SectionHeader('Enabling'),
        const SizedBox(height: 12),
        EnablingSection(controller: c, onChanged: () => setState(() {})),

        const SizedBox(height: 24),
        SectionHeader('Pre-Trial Details'),
        const SizedBox(height: 12),
        PreTrialDetailsSection(controller: c, drawingsSection: widget.drawingsSection),

        const SizedBox(height: 24),
        SectionHeader('Attendees'),
        const SizedBox(height: 12),
        AttendeesSection(controller: c),

        if (c.isPostTrial) ...[
          const SizedBox(height: 24),
          SectionHeader('Post-Trial Details'),
          const SizedBox(height: 4),
          PostTrialDetailsSection(controller: c, evidenceSection: widget.evidenceSection),
        ],
      ],
    );
  }
}
