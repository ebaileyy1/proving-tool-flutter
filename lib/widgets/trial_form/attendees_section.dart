import 'package:flutter/material.dart';
import 'package:proving_tool/models/attendee.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/trial_form/trial_form_controller.dart';
import 'package:proving_tool/widgets/trial_form/trial_text_field.dart';

class AttendeesSection extends StatefulWidget {
  const AttendeesSection({super.key, required this.controller});

  final TrialFormController controller;

  @override
  State<AttendeesSection> createState() => _AttendeesSectionState();
}

class _AttendeesSectionState extends State<AttendeesSection> {
  TrialFormController get _c => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._c.attendees.asMap().entries.map((entry) {
          final index = entry.key;
          final attendee = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.subBackground,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendee ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                    ),
                    if (_c.attendees.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                        onPressed: () => setState(() {
                          _c.attendees[index].dispose();
                          _c.attendees.removeAt(index);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TrialTextField(attendee.firstName, 'First Name', dense: true)),
                    const SizedBox(width: 12),
                    Expanded(child: TrialTextField(attendee.lastName, 'Last Name', dense: true)),
                  ],
                ),
                const SizedBox(height: 12),
                TrialTextField(attendee.company, 'Company', dense: true),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _c.attendees.add(Attendee())),
          icon: const Icon(Icons.person_add),
          label: const Text('Add another attendee'),
        ),
      ],
    );
  }
}
