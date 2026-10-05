import 'package:flutter/material.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/utils/enabling_checklist.dart';
import 'package:proving_tool/widgets/enabling_checklist_widgets.dart';
import 'package:proving_tool/widgets/trial_form/trial_form_controller.dart';

/// Pre-start checklist. Proving Scripts is a plain yes/no; Permits, Safety and
/// Site Access each have an "applies" toggle that reveals their items.
class EnablingSection extends StatefulWidget {
  const EnablingSection({super.key, required this.controller, required this.onChanged});

  final TrialFormController controller;
  final VoidCallback onChanged;

  @override
  State<EnablingSection> createState() => _EnablingSectionState();
}

class _EnablingSectionState extends State<EnablingSection> {
  TrialFormController get _c => widget.controller;

  void _notify() {
    setState(() {});
    widget.onChanged();
  }

  bool _isChecked(String field) => switch (field) {
    kEnablingPermitsRequired => _c.permitsRequired,
    kEnablingSafetyRequired => _c.safetyRequired,
    kEnablingAccessRequired => _c.accessRequired,
    _ => _c.enablingFlags[field] ?? false,
  };

  void _toggle(String field, bool value) {
    switch (field) {
      case kEnablingPermitsRequired:
        _setPermitsRequired(value);
      case kEnablingSafetyRequired:
        _c.safetyRequired = value;
      case kEnablingAccessRequired:
        _c.accessRequired = value;
      default:
        _c.setEnablingChecked(field, value);
    }
    _notify();
  }

  // Turning Permits on pushes the start date out to the 14-day minimum if needed,
  // without opening the picker.
  void _setPermitsRequired(bool value) {
    _c.permitsRequired = value;
    if (value) {
      final min = dateOnly(DateTime.now()).add(const Duration(days: 14));
      if (_c.startDate.isBefore(min)) {
        _c.startDate = min;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnablingStatusBanner(
          complete: _c.isEnablingComplete,
          incompleteText:
              'Check off Proving Scripts (or give a reason) before this trial can move to In Progress or Completed. Permits/Safety/Site Access below are for tracking - nothing there blocks starting.',
        ),
        const SizedBox(height: 16),
        EnablingChecklist(
          provingScriptsLabel: 'Proving Scripts',
          isChecked: _isChecked,
          reason: (field) => _c.enablingReasons[field] ?? '',
          onToggle: _toggle,
          onEditReason: (field, text) {
            _c.enablingReasons[field] = text;
            _notify();
          },
        ),
      ],
    );
  }
}
