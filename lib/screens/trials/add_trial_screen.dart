import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/file_picker_helper.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/trial_form.dart';

class AddTrialScreen extends StatefulWidget {
  const AddTrialScreen({super.key, this.prefill});

  /// When set (used by "Duplicate" on an existing trial), the form starts
  /// pre-filled from these fields instead of blank.
  final Map<String, dynamic>? prefill;

  @override
  State<AddTrialScreen> createState() => _AddTrialScreenState();
}

class _AddTrialScreenState extends State<AddTrialScreen> {
  final _supabase = Supabase.instance.client;
  late final TrialFormController _form;
  bool _isLoading = false;
  final List<PlatformFile> _drawingFiles = [];
  final List<PlatformFile> _evidenceFiles = [];

  @override
  void initState() {
    super.initState();
    _form = widget.prefill == null
        ? TrialFormController()
        : TrialFormController.fromExisting(
            widget.prefill!,
            resetForDuplicate: true,
          );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _pickDrawings() async {
    final files = await pickOrCaptureFiles(context);
    if (files.isNotEmpty) {
      setState(() => _drawingFiles.addAll(files));
    }
  }

  Future<void> _pickEvidence() async {
    final files = await pickOrCaptureFiles(context);
    if (files.isNotEmpty) {
      setState(() => _evidenceFiles.addAll(files));
    }
  }

  Future<void> _saveTrial() async {
    if (_form.fullname.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a trial name')),
      );
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = AppServices.of(context).trialRepository;
      final result = await repo.createTrial(
        fields: {
          ..._form.buildFieldsMap(),
          'posted_by': user.id,
        },
        drawings: _drawingFiles.map(PickedFileAttachment.fromPlatformFile).toList(),
        evidence: _evidenceFiles.map(PickedFileAttachment.fromPlatformFile).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.savedOnline
                  ? 'Trial saved'
                  : "Saved — will sync when you're back online",
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      logError('Error saving trial', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trial: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _fileList(List<PlatformFile> files, VoidCallback onAdd, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upload ${category == 'drawing' ? 'drawings' : 'evidence files'}',
              style: const TextStyle(color: AppColors.otherText, fontSize: 13),
            ),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.upload_file),
              label: const Text('Add Files'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          Text(
            'No ${category == 'drawing' ? 'drawings' : 'evidence files'} added yet.',
            style: const TextStyle(color: AppColors.otherText),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(fileEmojiForExtension(file.name.split('.').last), style: const TextStyle(fontSize: 24)),
                  title: Text(file.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    onPressed: () => setState(() => files.removeAt(index)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Add Trial'),
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
                  drawingsSection: _fileList(_drawingFiles, _pickDrawings, 'drawing'),
                  evidenceSection: _fileList(_evidenceFiles, _pickEvidence, 'evidence'),
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
                      : const Text('Save Trial', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
