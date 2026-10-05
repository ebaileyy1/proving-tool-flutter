import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/calendar/calendar_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/file_picker_helper.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/status_badge.dart';
import 'package:proving_tool/widgets/trial_form.dart';

class AddTrialScreen extends StatefulWidget {
  const AddTrialScreen({super.key, this.prefill});

  /// Set when duplicating; the form starts pre-filled from these fields.
  final Map<String, dynamic>? prefill;

  @override
  State<AddTrialScreen> createState() => _AddTrialScreenState();
}

const _kStepLabels = ['Basics', 'Enabling', 'Pre-Trial', 'Attendees', 'Review'];

class _AddTrialScreenState extends State<AddTrialScreen> {
  final _supabase = Supabase.instance.client;
  late final TrialFormController _form;
  int _step = 0;
  bool _isLoading = false;
  final List<PlatformFile> _drawingFiles = [];
  final List<PlatformFile> _evidenceFiles = [];

  @override
  void initState() {
    super.initState();
    _form = widget.prefill == null
        ? TrialFormController()
        : TrialFormController.fromExisting(widget.prefill!, resetForDuplicate: true);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _pickFiles(List<PlatformFile> target) async {
    final files = await pickOrCaptureFiles(context);
    if (files.isNotEmpty) {
      setState(() => target.addAll(files));
    }
  }

  bool get _basicsValid => _form.fullname.text.trim().isNotEmpty;

  void _goNext() {
    if (_step == 0 && !_basicsValid) {
      showMessage(context, 'Please enter a trial name');
      return;
    }
    if (_step < _kStepLabels.length - 1) {
      setState(() => _step += 1);
    } else {
      _saveTrial();
    }
  }

  void _goBack() {
    if (_step > 0) setState(() => _step -= 1);
  }

  Future<void> _saveTrial() async {
    if (!_basicsValid) {
      setState(() => _step = 0);
      showMessage(context, 'Please enter a trial name');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = AppServices.of(context).trialRepository;
      final result = await repo.createTrial(
        fields: {..._form.buildFieldsMap(), 'posted_by': user.id},
        drawings: _drawingFiles.map(PickedFileAttachment.fromPlatformFile).toList(),
        evidence: _evidenceFiles.map(PickedFileAttachment.fromPlatformFile).toList(),
      );

      if (mounted) {
        showMessage(
          context,
          result.savedOnline ? 'Trial saved' : "Saved - will sync when you're back online",
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      logError('Error saving trial', e);
      if (mounted) {
        showMessage(context, 'Error saving trial: $e');
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
                  leading: Text(
                    fileEmojiForExtension(file.name.split('.').last),
                    style: const TextStyle(fontSize: 24),
                  ),
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

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
      child: Row(
        children: [
          for (var i = 0; i < _kStepLabels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: i <= _step ? AppColors.accent : AppColors.border,
                ),
              ),
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _step
                        ? AppColors.accent
                        : (i == _step ? AppColors.navy : Colors.white),
                    border: Border.all(
                      color: i <= _step ? AppColors.accent : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: i < _step
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: i == _step ? Colors.white : AppColors.otherText,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _kStepLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == _step ? FontWeight.bold : FontWeight.normal,
                    color: i == _step ? AppColors.navy : AppColors.otherText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.otherText,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  String _fileCount(List<PlatformFile> files) =>
      '${files.length} file${files.length == 1 ? '' : 's'}';

  Widget _reviewStep() {
    final attendeeCount = _form.attendees.where((a) => !a.isEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          children: [
            Text(
              _form.fullname.text.trim().isEmpty ? 'Untitled trial' : _form.fullname.text.trim(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(status: _form.status),
                MetaTag(icon: Icons.science_outlined, label: _form.type),
                MetaTag(icon: Icons.location_on_outlined, label: _form.terminal),
                MetaTag(icon: Icons.pin_drop_outlined, label: _form.subArea.text.trim()),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            _reviewSummaryRow('Start Date', _form.startDate.toLocal().toString().split(' ')[0]),
            _reviewSummaryRow(
              'End Date',
              _form.endDate == null ? 'Not set' : _form.endDate!.toLocal().toString().split(' ')[0],
            ),
            _reviewSummaryRow('Enabling', _form.isEnablingComplete ? 'Complete' : 'Incomplete'),
            _reviewSummaryRow(
              'Attendees',
              attendeeCount == 0 ? 'None added' : '$attendeeCount added',
            ),
            _reviewSummaryRow('Drawings', _fileCount(_drawingFiles)),
            if (_form.isPostTrial) _reviewSummaryRow('Evidence Files', _fileCount(_evidenceFiles)),
          ],
        ),
        if (_form.isPostTrial) ...[
          const SizedBox(height: 16),
          const SectionHeaderLite('Post-Trial Details'),
          const SizedBox(height: 12),
          PostTrialDetailsSection(
            controller: _form,
            evidenceSection: _fileList(
              _evidenceFiles,
              () => _pickFiles(_evidenceFiles),
              'evidence',
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return TrialInfoSection(
          controller: _form,
          onChanged: () => setState(() {}),
          onViewCalendar: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
        );
      case 1:
        return EnablingSection(controller: _form, onChanged: () => setState(() {}));
      case 2:
        return PreTrialDetailsSection(
          controller: _form,
          drawingsSection: _fileList(_drawingFiles, () => _pickFiles(_drawingFiles), 'drawing'),
        );
      case 3:
        return AttendeesSection(controller: _form);
      default:
        return _reviewStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _kStepLabels.length - 1;
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
                _stepIndicator(),
                _stepContent(),
                const SizedBox(height: 28),
                Row(
                  children: [
                    if (_step > 0)
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _goBack,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _goNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isLastStep ? 'Save Trial' : 'Next',
                              style: const TextStyle(fontSize: 15),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Lighter header for sub-sections in the review step.
class SectionHeaderLite extends StatelessWidget {
  const SectionHeaderLite(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
    );
  }
}
