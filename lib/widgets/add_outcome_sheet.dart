import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/loading_button.dart';
import 'package:proving_tool/widgets/trial_form.dart';

/// Quick outcome sheet (status plus the post-trial fields) for a trial whose
/// date has arrived. Returns true if saved.
Future<bool?> showAddOutcomeSheet(BuildContext context, TrialListItem item) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddOutcomeSheet(item: item),
  );
}

class _AddOutcomeSheet extends StatefulWidget {
  const _AddOutcomeSheet({required this.item});

  final TrialListItem item;

  @override
  State<_AddOutcomeSheet> createState() => _AddOutcomeSheetState();
}

class _AddOutcomeSheetState extends State<_AddOutcomeSheet> {
  late final TrialFormController _form;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _form = TrialFormController.fromExisting(widget.item.data);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = AppServices.of(context).trialRepository;
      await repo.updateTrial(
        remoteId: widget.item.remoteId,
        localId: widget.item.localId,
        fields: _form.buildFieldsMap(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, 'Error saving outcome: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _choice(String status, IconData icon, Color color) => Expanded(
    child: _OutcomeChoiceButton(
      label: status,
      icon: icon,
      color: color,
      selected: _form.status == status,
      onTap: () => setState(() => _form.status = status),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final canSave = _form.isPostTrial;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.data['fullname']?.toString() ?? 'Trial',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text('How did it go?', style: TextStyle(color: AppColors.otherText)),
            const SizedBox(height: 16),
            Row(
              children: [
                _choice('Completed', Icons.check_circle, AppColors.success),
                const SizedBox(width: 12),
                _choice('Failed', Icons.cancel, AppColors.error),
              ],
            ),
            if (canSave) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _form.howTrialWent,
                decoration: const InputDecoration(labelText: 'How the Trial Went'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _form.actualOutcome,
                decoration: const InputDecoration(labelText: 'Actual Outcome'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _form.evidenceSummary,
                decoration: const InputDecoration(
                  labelText: 'Evidence Summary',
                  hintText: 'Summarise the evidence collected',
                ),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 20),
            LoadingButton(
              isLoading: _isSaving,
              onPressed: canSave ? _save : null,
              label: 'Save Outcome',
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeChoiceButton extends StatelessWidget {
  const _OutcomeChoiceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.subBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.otherText),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.otherText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
