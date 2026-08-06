import 'package:flutter/material.dart';
import 'package:proving_tool/models/attendee.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/section_header.dart';

const kTrialTypes = [
  'Desktop',
  'Dimensional',
  'First of Type',
  'Unit Trial',
  'Basic Trial',
  'Advanced Trial',
  'Live Rehearsal',
];
const kTrialTerminals = ['T1', 'T2', 'T3', 'T4', 'T5'];
const kTrialStatuses = ['Pending', 'In Progress', 'Completed', 'Failed'];

/// Everything the Add and Edit trial screens need to hold the form state
/// and turn it into the field map `TrialRepository` expects — previously
/// duplicated (and drifted apart) between the two screens.
class TrialFormController {
  TrialFormController({
    String fullname = '',
    String description = '',
    String expectedOutcome = '',
    String runPlan = '',
    String howTrialWent = '',
    String actualOutcome = '',
    String evidenceSummary = '',
    List<Attendee>? attendees,
    this.type = 'Desktop',
    this.terminal = 'T1',
    this.status = 'Pending',
    DateTime? startDate,
    this.endDate,
  }) : fullname = TextEditingController(text: fullname),
       description = TextEditingController(text: description),
       expectedOutcome = TextEditingController(text: expectedOutcome),
       runPlan = TextEditingController(text: runPlan),
       howTrialWent = TextEditingController(text: howTrialWent),
       actualOutcome = TextEditingController(text: actualOutcome),
       evidenceSummary = TextEditingController(text: evidenceSummary),
       attendees = attendees ?? [Attendee()],
       startDate = startDate ?? DateTime.now();

  /// Pre-fills from an existing trial's field map — used by Edit (editing
  /// that trial) and by Add's "Duplicate" flow ([resetForDuplicate] drops
  /// the post-trial fields and resets status/start-date/end-date, since
  /// those describe the run being copied from, not a fresh one).
  factory TrialFormController.fromExisting(
    Map<String, dynamic> trial, {
    bool resetForDuplicate = false,
  }) {
    final type = trial['type_of_trial']?.toString();
    final terminal = trial['terminal_of_trial']?.toString();
    final status = trial['status_of_trial']?.toString();
    return TrialFormController(
      fullname: trial['fullname']?.toString() ?? '',
      description: trial['description_of_trial']?.toString() ?? '',
      expectedOutcome: trial['expected_outcome']?.toString() ?? '',
      runPlan: trial['run_plan']?.toString() ?? '',
      howTrialWent: resetForDuplicate
          ? ''
          : trial['how_trial_went']?.toString() ?? '',
      actualOutcome: resetForDuplicate
          ? ''
          : trial['actual_outcome']?.toString() ?? '',
      evidenceSummary: resetForDuplicate
          ? ''
          : trial['evidence_summary']?.toString() ?? '',
      attendees: parseAttendeesText(trial['attendees']?.toString() ?? ''),
      type: kTrialTypes.contains(type) ? type! : kTrialTypes.first,
      terminal: kTrialTerminals.contains(terminal)
          ? terminal!
          : kTrialTerminals.first,
      status: resetForDuplicate
          ? kTrialStatuses.first
          : (kTrialStatuses.contains(status) ? status! : kTrialStatuses.first),
      startDate: resetForDuplicate
          ? null
          : DateTime.tryParse(trial['date_of_start']?.toString() ?? ''),
      endDate: resetForDuplicate
          ? null
          : DateTime.tryParse(trial['date_of_completion']?.toString() ?? ''),
    );
  }

  final TextEditingController fullname;
  final TextEditingController description;
  final TextEditingController expectedOutcome;
  final TextEditingController runPlan;
  final TextEditingController howTrialWent;
  final TextEditingController actualOutcome;
  final TextEditingController evidenceSummary;
  final List<Attendee> attendees;
  String type;
  String terminal;
  String status;
  DateTime startDate;
  DateTime? endDate;

  bool get isPostTrial => status == 'Completed' || status == 'Failed';

  String get attendeesText => attendees
      .where((a) => !a.isEmpty)
      .map((a) => a.toText())
      .join('\n');

  /// The map shape `TrialRepository.createTrial`/`updateTrial` expect.
  /// `posted_by` is create-only and added by the caller, not here.
  Map<String, dynamic> buildFieldsMap() {
    return {
      'fullname': fullname.text.trim(),
      'description_of_trial': description.text.trim(),
      'expected_outcome': expectedOutcome.text.trim(),
      'run_plan': runPlan.text.trim(),
      'attendees': attendeesText,
      'how_trial_went': isPostTrial ? howTrialWent.text.trim() : null,
      'actual_outcome': isPostTrial ? actualOutcome.text.trim() : null,
      'evidence_summary': isPostTrial ? evidenceSummary.text.trim() : null,
      'date_of_start': startDate.toIso8601String(),
      'type_of_trial': type,
      'terminal_of_trial': terminal,
      'status_of_trial': status,
      'date_of_completion': endDate?.toIso8601String(),
    };
  }

  void dispose() {
    fullname.dispose();
    description.dispose();
    expectedOutcome.dispose();
    runPlan.dispose();
    howTrialWent.dispose();
    actualOutcome.dispose();
    evidenceSummary.dispose();
    for (final a in attendees) {
      a.dispose();
    }
  }
}

/// Renders the full trial form body (info, pre-trial details, attendees,
/// conditional post-trial section) for a [TrialFormController]. Both
/// `AddTrialScreen` and `EditTrialScreen` embed this; [drawingsSection]/
/// [evidenceSection] let Add slot its file pickers in at the right spot
/// without Edit (which doesn't manage files) needing to know about them.
class TrialFormFields extends StatefulWidget {
  const TrialFormFields({
    super.key,
    required this.controller,
    this.drawingsSection,
    this.evidenceSection,
  });

  final TrialFormController controller;
  final Widget? drawingsSection;
  final Widget? evidenceSection;

  @override
  State<TrialFormFields> createState() => _TrialFormFieldsState();
}

class _TrialFormFieldsState extends State<TrialFormFields> {
  TrialFormController get _c => widget.controller;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _c.startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.endDate ?? _c.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _c.endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Trial Information'),
        const SizedBox(height: 12),
        TextField(
          controller: _c.fullname,
          decoration: const InputDecoration(labelText: 'Trial Name'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _c.type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: kTrialTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _c.type = v!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _c.terminal,
                decoration: const InputDecoration(labelText: 'Terminal'),
                items: kTrialTerminals
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _c.terminal = v!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _c.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: kTrialStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _c.status = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(
                  'Start date: ${_c.startDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(
                  _c.endDate == null
                      ? 'Select end date'
                      : 'End date: ${_c.endDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickEndDate,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Pre-Trial Details
        SectionHeader('Pre-Trial Details'),
        const SizedBox(height: 12),
        TextField(
          controller: _c.description,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _c.expectedOutcome,
          decoration: const InputDecoration(labelText: 'Expected Outcome'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _c.runPlan,
          decoration: const InputDecoration(labelText: 'Run Plan'),
          maxLines: 4,
        ),
        if (widget.drawingsSection != null) ...[
          const SizedBox(height: 16),
          widget.drawingsSection!,
        ],

        const SizedBox(height: 24),

        // Attendees
        SectionHeader('Attendees'),
        const SizedBox(height: 12),
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
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.error,
                        ),
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
                    Expanded(
                      child: TextField(
                        controller: attendee.firstName,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: attendee.lastName,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: attendee.company,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    isDense: true,
                  ),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _c.attendees.add(Attendee())),
          icon: const Icon(Icons.person_add),
          label: const Text('Add another attendee'),
        ),

        // Post-Trial Details
        if (_c.isPostTrial) ...[
          const SizedBox(height: 24),
          SectionHeader('Post-Trial Details'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _c.status == 'Completed'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _c.status == 'Completed'
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _c.status == 'Completed' ? Icons.check_circle : Icons.cancel,
                  color: _c.status == 'Completed'
                      ? AppColors.success
                      : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trial marked as ${_c.status} — fill in post-trial details below',
                    style: TextStyle(
                      fontSize: 13,
                      color: _c.status == 'Completed'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c.howTrialWent,
            decoration: const InputDecoration(labelText: 'How the Trial Went'),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c.actualOutcome,
            decoration: const InputDecoration(labelText: 'Actual Outcome'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c.evidenceSummary,
            decoration: const InputDecoration(
              labelText: 'Evidence Summary',
              hintText: 'Summarise the evidence collected',
            ),
            maxLines: 3,
          ),
          if (widget.evidenceSection != null) ...[
            const SizedBox(height: 16),
            widget.evidenceSection!,
          ],
        ],
      ],
    );
  }

}
