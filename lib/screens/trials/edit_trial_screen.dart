import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/calendar/calendar_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/trial_form.dart';

class EditTrialScreen extends StatefulWidget {
  final Map<String, dynamic> trial;

  /// Set when the trial hasn't synced yet; edits go to the queued local copy.
  final String? localId;

  const EditTrialScreen({super.key, required this.trial, this.localId});

  @override
  State<EditTrialScreen> createState() => _EditTrialScreenState();
}

class _EditTrialScreenState extends State<EditTrialScreen> {
  late final TrialFormController _form;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _form = TrialFormController.fromExisting(widget.trial);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _saveTrial() async {
    if (_form.fullname.text.trim().isEmpty) {
      showMessage(context, 'Please enter a trial name');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _performSave();
    } on TrialConflictException {
      if (!mounted) return;
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('This trial changed since you opened it'),
          content: const Text(
            "Someone else saved changes to this trial while you were "
            "editing. You can overwrite their changes with yours, or "
            "cancel and reload the latest version yourself.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Overwrite anyway', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (overwrite == true) {
        try {
          await _performSave(force: true);
        } catch (e) {
          logError('Error updating trial (forced)', e);
          if (mounted) {
            showMessage(context, 'Error updating trial: $e');
          }
        }
      }
    } catch (e) {
      logError('Error updating trial', e);
      if (mounted) {
        showMessage(context, 'Error updating trial: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [force] skips the conflict check, for the "Overwrite anyway" choice.
  Future<void> _performSave({bool force = false}) async {
    final repo = AppServices.of(context).trialRepository;
    final remoteId = widget.trial['id'] == null ? null : (widget.trial['id'] as num).toInt();
    final result = await repo.updateTrial(
      remoteId: remoteId,
      localId: widget.localId,
      fields: _form.buildFieldsMap(),
      baseUpdatedAt: force ? null : widget.trial['updated_at']?.toString(),
    );

    if (mounted) {
      showMessage(
        context,
        result.savedOnline ? 'Trial updated' : "Saved - will sync when you're back online",
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Edit Trial'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TrialFormFields(
                  controller: _form,
                  onViewCalendar: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTrial,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
