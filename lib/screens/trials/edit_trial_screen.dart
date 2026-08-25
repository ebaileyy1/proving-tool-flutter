import 'package:flutter/material.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/trial_form.dart';

class EditTrialScreen extends StatefulWidget {
  final Map<String, dynamic> trial;

  /// Set when [trial] hasn't synced to Supabase yet — edits are applied to
  /// the queued local copy instead of a server row.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a trial name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = AppServices.of(context).trialRepository;
      final remoteId = widget.trial['id'] == null
          ? null
          : (widget.trial['id'] as num).toInt();
      final result = await repo.updateTrial(
        remoteId: remoteId,
        localId: widget.localId,
        fields: _form.buildFieldsMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.savedOnline
                  ? 'Trial updated'
                  : "Saved — will sync when you're back online",
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      logError('Error updating trial', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating trial: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                TrialFormFields(controller: _form),
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
