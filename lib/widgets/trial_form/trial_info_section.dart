import 'package:flutter/material.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/utils/enabling_checklist.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/trial_date_picker.dart';
import 'package:proving_tool/widgets/trial_form/trial_form_controller.dart';
import 'package:proving_tool/widgets/trial_form/trial_text_field.dart';

/// Name, type/terminal/status and dates. [onChanged] fires on every change so
/// callers can rebuild when status changes.
class TrialInfoSection extends StatefulWidget {
  const TrialInfoSection({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onViewCalendar,
  });

  final TrialFormController controller;
  final VoidCallback onChanged;

  /// Shows a "View Calendar" link next to Start Date.
  final VoidCallback? onViewCalendar;

  @override
  State<TrialInfoSection> createState() => _TrialInfoSectionState();
}

class _TrialInfoSectionState extends State<TrialInfoSection> {
  TrialFormController get _c => widget.controller;

  // Autocomplete needs focusNode and textEditingController supplied together or neither.
  final _subAreaFocusNode = FocusNode();

  @override
  void dispose() {
    _subAreaFocusNode.dispose();
    super.dispose();
  }

  // Sub-areas already used for the selected terminal, so spellings stay consistent.
  List<String> _subAreaSuggestions(BuildContext context) {
    final trials = AppServices.of(context).trialRepository.trials.value;
    final seen = <String>{};
    for (final item in trials) {
      if (item.data['terminal_of_trial']?.toString() != _c.terminal) continue;
      final value = item.data['sub_area_of_trial']?.toString().trim();
      if (value != null && value.isNotEmpty) seen.add(value);
    }
    final list = seen.toList()..sort();
    return list;
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  String _ymd(DateTime d) => d.toLocal().toString().split(' ')[0];

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateTile(String text, VoidCallback onTap, {bool warn = false}) {
    return Expanded(
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: warn ? AppColors.warning : AppColors.border),
        ),
        title: Text(text),
        trailing: const Icon(Icons.calendar_today),
        onTap: onTap,
      ),
    );
  }

  // Permits means start date >= today+14.
  DateTime get _minStartDate {
    if (!_c.permitsRequired) return DateTime(2020);
    return dateOnly(DateTime.now()).add(const Duration(days: 14));
  }

  bool get _startDateBelowMinimum => _c.startDate.isBefore(_minStartDate);

  Future<void> _pickStartDate() async {
    final minDate = _minStartDate;
    final picked = await showTrialDatePicker(
      context: context,
      initialDate: _c.startDate.isBefore(minDate) ? minDate : _c.startDate,
      minDate: minDate,
      maxDate: DateTime(2030),
      countsByDay: tripCountsByDay(context),
    );
    if (picked != null) _update(() => _c.startDate = picked);
  }

  Future<void> _setStatus(String value) async {
    var blocked = (value == 'In Progress' || value == 'Completed') && !_c.isEnablingComplete;
    if (blocked) {
      // Let the user give a reason right here instead of hunting through the checklist.
      final resolved = await promptForMissingEnabling(
        context: context,
        missingItems: _c.missingEnablingItems,
        isChecked: (field) => _c.enablingFlags[field] ?? false,
        setChecked: (field, v) => setState(() => _c.setEnablingChecked(field, v)),
        reasons: _c.enablingReasons,
        setReason: (field, v) => setState(() => _c.enablingReasons[field] = v),
      );
      blocked = !resolved;
      widget.onChanged();
    }
    if (blocked) {
      if (!mounted) return;
      showMessage(context, 'Finish the Enabling checklist before starting this trial.');
      return;
    }
    setState(() => _c.status = value);
    widget.onChanged();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.endDate ?? _c.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) _update(() => _c.endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrialTextField(_c.fullname, 'Trial Name'),
        const SizedBox(height: 16),
        Row(
          children: [
            _dropdown('Type', _c.type, kTrialTypes, (v) => _update(() => _c.type = v!)),
            const SizedBox(width: 16),
            _dropdown(
              'Terminal',
              _c.terminal,
              kTrialTerminals,
              (v) => _update(() => _c.terminal = v!),
            ),
            const SizedBox(width: 16),
            _dropdown('Status', _c.status, kTrialStatuses, (v) => _setStatus(v!)),
          ],
        ),
        if (!_c.isEnablingComplete) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Complete the Enabling checklist below to move this trial to In Progress or Completed.",
                    style: TextStyle(fontSize: 12, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Autocomplete<String>(
          textEditingController: _c.subArea,
          focusNode: _subAreaFocusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            final suggestions = _subAreaSuggestions(context);
            if (query.isEmpty) return suggestions;
            return suggestions.where((s) => s.toLowerCase().contains(query));
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Sub-Area', hintText: 'Optional'),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _dateTile(
              'Start date: ${_ymd(_c.startDate)}',
              _pickStartDate,
              warn: _startDateBelowMinimum,
            ),
            const SizedBox(width: 16),
            _dateTile(
              _c.endDate == null ? 'Select end date' : 'End date: ${_ymd(_c.endDate!)}',
              _pickEndDate,
            ),
          ],
        ),
        if (_c.permitsRequired || widget.onViewCalendar != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (_c.permitsRequired)
                Expanded(
                  child: Text(
                    _startDateBelowMinimum
                        ? "Permits need a minimum of 14 days' notice - pick a date on or after ${_ymd(_minStartDate)}."
                        : "Permits require a minimum of 14 days' notice before the start date.",
                    style: TextStyle(
                      fontSize: 12,
                      color: _startDateBelowMinimum ? AppColors.warning : AppColors.otherText,
                    ),
                  ),
                ),
              if (widget.onViewCalendar != null)
                TextButton.icon(
                  onPressed: widget.onViewCalendar,
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('View Calendar'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
