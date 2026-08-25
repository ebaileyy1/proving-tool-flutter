import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proving_tool/config.dart';
import 'package:proving_tool/models/attendee.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/trials/add_trial_screen.dart';
import 'package:proving_tool/screens/trials/edit_trial_screen.dart';
import 'package:proving_tool/screens/pdf/trial_pdf.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/services/notification_service.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/file_picker_helper.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/widgets/add_outcome_sheet.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/pending_sync_chip.dart';
import 'package:proving_tool/widgets/section_header.dart';

class ViewTrialScreen extends StatefulWidget {
  final TrialListItem item;

  const ViewTrialScreen({super.key, required this.item});

  @override
  State<ViewTrialScreen> createState() => _ViewTrialScreenState();
}

class _ViewTrialScreenState extends State<ViewTrialScreen> {
  final _supabase = Supabase.instance.client;
  late final TrialRepository _repo;
  late final ConnectivityService _connectivity;
  bool _repoInitialized = false;
  final _observationController = TextEditingController();
  Map<String, dynamic> _trial = {};
  List<Map<String, dynamic>> _observations = [];
  Map<int, List<Map<String, dynamic>>> _replies = {};
  final Map<int, bool> _showReplyBox = {};
  final Map<int, TextEditingController> _replyControllers = {};
  List<Map<String, dynamic>> _files = [];
  List<Map<String, dynamic>> _drawings = [];
  List<Map<String, dynamic>> _evidenceFiles = [];
  bool _isLoading = true;
  bool _isUploadingDrawing = false;
  bool _isUploadingEvidence = false;
  bool _isOwnerOrAdmin = false;
  bool _isExportingPdf = false;
  bool _isDownloadingAll = false;

  /// True while this trial has no server id yet (created/edited offline
  /// and still queued). Observations, PDF export and delete all need a
  /// real trial on the server, so they stay unavailable until it syncs.
  bool get _isPendingLocal => widget.item.localId != null;

  int? get _remoteId => widget.item.remoteId;

  /// True once this trial's start date has arrived (today or earlier) and
  /// it hasn't been marked Completed/Failed yet — a nudge to log the
  /// outcome instead of leaving it sitting as Pending/In Progress.
  bool get _needsOutcome {
    final status = _trial['status_of_trial']?.toString();
    if (status != 'Pending' && status != 'In Progress') return false;
    final date = DateTime.tryParse(_trial['date_of_start']?.toString() ?? '');
    if (date == null) return false;
    final today = DateTime.now();
    final startDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return !startDate.isAfter(todayDate);
  }

  @override
  void initState() {
    super.initState();
    _trial = Map<String, dynamic>.from(widget.item.data);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_repoInitialized) {
      _repoInitialized = true;
      final services = AppServices.of(context);
      _repo = services.trialRepository;
      _connectivity = services.connectivity;
      _loadData();
    }
  }

  bool _requireOnline(String message) {
    if (_connectivity.isOnline.value) return true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    return false;
  }

  @override
  void dispose() {
    _observationController.dispose();
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isPendingLocal) {
      await _loadLocalPreview();
    } else {
      await _loadRemoteData();
    }
  }

  Future<void> _loadLocalPreview() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getLocalPendingTrialData(widget.item.localId!);
      final pendingFiles = await _repo.getLocalFilesFor(
        trialLocalId: widget.item.localId,
      );
      final filesList = pendingFiles
          .map(
            (f) => {
              'original_name': f.originalName,
              'file_category': f.category,
              'uploaded_at': f.createdAt.toIso8601String(),
            },
          )
          .toList();
      setState(() {
        _trial = data ?? widget.item.data;
        _files = filesList;
        _drawings = filesList.where((f) => f['file_category'] == 'drawing').toList();
        _evidenceFiles = filesList.where((f) => f['file_category'] != 'drawing').toList();
        _isOwnerOrAdmin = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRemoteData() async {
    setState(() => _isLoading = true);
    try {
      final trialData = await _supabase
          .from('topics')
          .select()
          .eq('id', _remoteId!)
          .single();

      final observations = await _supabase
          .from('observations_with_profiles')
          .select()
          .eq('topic_id', _remoteId!)
          .order('created_at', ascending: true);

      final allFiles = await _supabase
          .from('files')
          .select()
          .eq('topic_id', _remoteId!)
          .order('uploaded_at', ascending: false);

      final userId = _supabase.auth.currentUser!.id;

      final profiles = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', userId);

      bool isAdmin = false;
      if (profiles.isNotEmpty) {
        isAdmin = profiles[0]['is_admin'] == true;
      }

      final Map<int, List<Map<String, dynamic>>> repliesMap = {};
      for (final obs in observations) {
        final obsId = (obs['id'] as num).toInt();
        final replies = await _supabase
            .from('observation_replies_with_profiles')
            .select()
            .eq('observation_id', obsId)
            .order('created_at', ascending: true);
        repliesMap[obsId] = List<Map<String, dynamic>>.from(replies);
      }

      final allFilesList = List<Map<String, dynamic>>.from(allFiles);

      setState(() {
        _trial = Map<String, dynamic>.from(trialData);
        _observations = List<Map<String, dynamic>>.from(observations);
        _files = allFilesList;
        _drawings = allFilesList.where((f) => f['file_category'] == 'drawing').toList();
        _evidenceFiles = allFilesList.where((f) => f['file_category'] != 'drawing').toList();
        _replies = repliesMap;
        _isOwnerOrAdmin = trialData['posted_by'] == userId || isAdmin;
      });
    } catch (e) {
      logError('Error loading data', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addObservation() async {
    if (_observationController.text.trim().isEmpty) return;
    if (!_requireOnline('Adding an observation needs an internet connection.')) {
      return;
    }
    try {
      await _supabase.from('observations').insert({
        'topic_id': _remoteId,
        'posted_by': _supabase.auth.currentUser!.id,
        'content': _observationController.text.trim(),
      });

      final ownerId = _trial['posted_by']?.toString();
      if (ownerId != null) {
        await NotificationService.send(
          userId: ownerId,
          title: 'New observation on your trial',
          body: '"${_trial['fullname']}" has a new observation.',
          topicId: _remoteId,
        );
      }

      _observationController.clear();
      _loadData();
    } catch (e) {
      logError('Error adding observation', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding observation: $e')),
        );
      }
    }
  }

  Future<void> _addReply(int observationId) async {
    final controller = _replyControllers[observationId];
    if (controller == null || controller.text.trim().isEmpty) return;
    if (!_requireOnline('Replying needs an internet connection.')) return;
    try {
      await _supabase.from('observation_replies').insert({
        'observation_id': observationId,
        'posted_by': _supabase.auth.currentUser!.id,
        'content': controller.text.trim(),
      });

      final obs = _observations.firstWhere(
        (o) => (o['id'] as num).toInt() == observationId,
        orElse: () => {},
      );
      final obsAuthorId = obs['posted_by']?.toString();
      if (obsAuthorId != null) {
        await NotificationService.send(
          userId: obsAuthorId,
          title: 'Someone replied to your observation',
          body: 'New reply on "${_trial['fullname']}".',
          topicId: _remoteId,
        );
      }

      controller.clear();
      setState(() => _showReplyBox[observationId] = false);
      _loadData();
    } catch (e) {
      logError('Error adding reply', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding reply: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      await TrialPdf.generate(
        trial: _trial,
        observations: _observations,
        files: _files,
        supabaseUrl: SupabaseConfig.url,
      );
    } catch (e) {
      logError('Error generating PDF', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _uploadFile(String category) async {
    final file = await pickOrCaptureFile(context);
    if (file == null || file.bytes == null) return;

    if (category == 'drawing') {
      setState(() => _isUploadingDrawing = true);
    } else {
      setState(() => _isUploadingEvidence = true);
    }

    try {
      final result = await _repo.attachFile(
        remoteId: _remoteId,
        localId: widget.item.localId,
        file: PickedFileAttachment.fromPlatformFile(file),
        category: category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.savedOnline
                  ? '${category == 'drawing' ? 'Drawing' : 'Evidence file'} uploaded successfully'
                  : "Saved — will upload when you're back online",
            ),
          ),
        );
      }
      _loadData();
    } catch (e) {
      logError('Error uploading file', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDrawing = false;
          _isUploadingEvidence = false;
        });
      }
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    if (!_requireOnline('Downloading files needs an internet connection.')) {
      return;
    }
    try {
      final url = _supabase.storage
          .from('trial-files')
          .getPublicUrl(file['storage_path']);

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file')),
          );
        }
      }
    } catch (e) {
      logError('Error downloading file', e);
    }
  }

  Future<void> _downloadAllFiles(List<Map<String, dynamic>> files) async {
    if (files.isEmpty) return;
    setState(() => _isDownloadingAll = true);
    try {
      for (final file in files) {
        await _downloadFile(file);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      if (mounted) setState(() => _isDownloadingAll = false);
    }
  }

  Future<void> _deleteTrial() async {
    if (!_isPendingLocal &&
        !_requireOnline('Deleting a trial requires an internet connection.')) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trial'),
        content: const Text('Are you sure you want to delete this trial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (_isPendingLocal) {
          await _repo.deleteLocalPendingTrial(widget.item.localId!);
        } else {
          await _repo.deleteTrial(_remoteId!);
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        logError('Error deleting trial', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting trial: $e')),
          );
        }
      }
    }
  }

  Widget _filesCard({
    required String title,
    required List<Map<String, dynamic>> files,
    required String category,
    required bool isUploading,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionHeader(title),
                Row(
                  children: [
                    if (files.isNotEmpty && !_isPendingLocal)
                      TextButton.icon(
                        onPressed: _isDownloadingAll
                            ? null
                            : () => _downloadAllFiles(files),
                        icon: _isDownloadingAll
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_for_offline),
                        label: Text(_isDownloadingAll ? 'Downloading...' : 'Download all'),
                      ),
                    if (_isOwnerOrAdmin) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () => _uploadFile(category),
                        icon: isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(isUploading ? 'Uploading...' : 'Upload'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            files.isEmpty
                ? Text(
                    'No ${category == 'drawing' ? 'drawings' : 'evidence files'} uploaded yet.',
                    style: const TextStyle(color: AppColors.otherText),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final extension = file['original_name']?.toString().split('.').last;
                      return ListTile(
                        leading: Text(
                          fileEmojiForExtension(extension),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(file['original_name']?.toString() ?? ''),
                        subtitle: Text(
                          _isPendingLocal
                              ? "Queued — will upload when you're back online"
                              : file['uploaded_at']?.toString().split('T')[0] ?? '',
                        ),
                        trailing: _isPendingLocal
                            ? const Tooltip(
                                message: 'Not uploaded yet',
                                child: Icon(Icons.hourglass_top, size: 18, color: AppColors.otherText),
                              )
                            : IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => _downloadFile(file),
                              ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _trial['status_of_trial']?.toString() ?? '';
    final isPostTrial = status == 'Completed' || status == 'Failed';

    return Scaffold(
      appBar: AppHeader(
        title: _trial['fullname']?.toString() ?? 'Trial',
        statusChip: _isPendingLocal ? const PendingSyncChip() : null,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _connectivity.isOnline,
            builder: (context, isOnline, _) {
              final enabled = isOnline && !_isPendingLocal && !_isExportingPdf;
              return HeaderIconButton(
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                tooltip: !isOnline
                    ? 'PDF export needs an internet connection'
                    : _isPendingLocal
                        ? "Export needs this trial to sync first"
                        : 'Export as PDF',
                onPressed: enabled ? _exportPdf : null,
              );
            },
          ),
          HeaderIconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Duplicate as a new trial',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTrialScreen(prefill: _trial),
                ),
              );
            },
          ),
          if (_isOwnerOrAdmin) ...[
            HeaderIconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditTrialScreen(
                      trial: _trial,
                      localId: widget.item.localId,
                    ),
                  ),
                );
                if (result == true) _loadData();
              },
            ),
            HeaderIconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: _deleteTrial,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (_isPendingLocal) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.lightNavy),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_off, size: 18, color: AppColors.lightNavy),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "This trial hasn't synced yet — observations, PDF export and downloads will be available once it's online.",
                                  style: TextStyle(fontSize: 12, color: AppColors.navy),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_needsOutcome) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, size: 18, color: AppColors.warning),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  "This trial's date has arrived — add the outcome when you're ready.",
                                  style: TextStyle(fontSize: 12, color: AppColors.navy),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final saved = await showAddOutcomeSheet(context, widget.item);
                                  if (saved == true) _loadData();
                                },
                                child: const Text('Add Outcome'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Trial information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader('Trial Information'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _detailRow('Status', _trial['status_of_trial']?.toString())),
                                  Expanded(child: _detailRow('Type', _trial['type_of_trial']?.toString())),
                                  Expanded(child: _detailRow('Terminal', _trial['terminal_of_trial']?.toString())),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _detailRow('Start Date', _trial['date_of_start']?.toString().split('T')[0])),
                                  Expanded(child: _detailRow('End Date', _trial['date_of_completion']?.toString().split('T')[0])),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pre-trial details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader('Pre-Trial Details'),
                              const SizedBox(height: 12),
                              if (_trial['description_of_trial'] != null && _trial['description_of_trial'].toString().isNotEmpty)
                                _detailRow('Description', _trial['description_of_trial']?.toString()),
                              if (_trial['expected_outcome'] != null && _trial['expected_outcome'].toString().isNotEmpty)
                                _detailRow('Expected Outcome', _trial['expected_outcome']?.toString()),
                              if (_trial['run_plan'] != null && _trial['run_plan'].toString().isNotEmpty)
                                _detailRow('Run Plan', _trial['run_plan']?.toString()),
                              if (_trial['attendees'] != null && _trial['attendees'].toString().isNotEmpty)
                                _detailRow('Attendees', formatAttendeesForDisplay(_trial['attendees'].toString())),
                              if ((_trial['description_of_trial'] == null || _trial['description_of_trial'].toString().isEmpty) &&
                                  (_trial['expected_outcome'] == null || _trial['expected_outcome'].toString().isEmpty) &&
                                  (_trial['run_plan'] == null || _trial['run_plan'].toString().isEmpty) &&
                                  (_trial['attendees'] == null || _trial['attendees'].toString().isEmpty))
                                const Text(
                                  'No pre-trial details added yet.',
                                  style: TextStyle(color: AppColors.otherText, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Drawings (pre-trial)
                      _filesCard(
                        title: 'Drawings',
                        files: _drawings,
                        category: 'drawing',
                        isUploading: _isUploadingDrawing,
                      ),

                      // Post-trial details
                      if (isPostTrial) ...[
                        const SizedBox(height: 16),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: status == 'Completed' ? AppColors.success : AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      status == 'Completed' ? Icons.check_circle : Icons.cancel,
                                      color: status == 'Completed' ? AppColors.success : AppColors.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Post-Trial Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'Completed' ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Divider(
                                  color: status == 'Completed'
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.error.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 8),
                                if (_trial['how_trial_went'] != null && _trial['how_trial_went'].toString().isNotEmpty)
                                  _detailRow('How It Went', _trial['how_trial_went']?.toString()),
                                if (_trial['actual_outcome'] != null && _trial['actual_outcome'].toString().isNotEmpty)
                                  _detailRow('Actual Outcome', _trial['actual_outcome']?.toString()),
                                if (_trial['evidence_summary'] != null && _trial['evidence_summary'].toString().isNotEmpty)
                                  _detailRow('Evidence Summary', _trial['evidence_summary']?.toString()),
                                if ((_trial['how_trial_went'] == null || _trial['how_trial_went'].toString().isEmpty) &&
                                    (_trial['actual_outcome'] == null || _trial['actual_outcome'].toString().isEmpty) &&
                                    (_trial['evidence_summary'] == null || _trial['evidence_summary'].toString().isEmpty))
                                  const Text(
                                    'No post-trial details added yet. Edit the trial to add them.',
                                    style: TextStyle(color: AppColors.otherText, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Evidence files (post-trial)
                        _filesCard(
                          title: 'Evidence Files',
                          files: _evidenceFiles,
                          category: 'evidence',
                          isUploading: _isUploadingEvidence,
                        ),
                      ],

                      if (!_isPendingLocal) ...[
                      const SizedBox(height: 16),

                      // Observations
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader('Observations'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _observationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Add an observation',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _addObservation,
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _observations.isEmpty
                                  ? const Text(
                                      'No observations yet.',
                                      style: TextStyle(color: AppColors.otherText),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _observations.length,
                                      itemBuilder: (context, index) {
                                        final obs = _observations[index];
                                        final obsId = (obs['id'] as num).toInt();
                                        final obsReplies = _replies[obsId] ?? [];
                                        final showReply = _showReplyBox[obsId] ?? false;

                                        if (!_replyControllers.containsKey(obsId)) {
                                          _replyControllers[obsId] = TextEditingController();
                                        }

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.border),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      obs['content']?.toString() ?? '',
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.person, size: 12, color: AppColors.otherText),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          obs['username']?.toString() ?? 'Unknown',
                                                          style: const TextStyle(
                                                            color: AppColors.lightNavy,
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          obs['created_at']?.toString().split('T')[0] ?? '',
                                                          style: const TextStyle(
                                                            color: AppColors.otherText,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        TextButton.icon(
                                                          onPressed: () => setState(() {
                                                            _showReplyBox[obsId] = !showReply;
                                                          }),
                                                          icon: const Icon(Icons.reply, size: 14),
                                                          label: Text(
                                                            showReply ? 'Cancel' : 'Reply',
                                                            style: const TextStyle(fontSize: 12),
                                                          ),
                                                          style: TextButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              if (obsReplies.isNotEmpty)
                                                Container(
                                                  decoration: const BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(color: AppColors.border),
                                                    ),
                                                    color: AppColors.subBackground,
                                                  ),
                                                  child: ListView.separated(
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemCount: obsReplies.length,
                                                    separatorBuilder: (_, _) => const Divider(height: 1),
                                                    itemBuilder: (context, rIndex) {
                                                      final reply = obsReplies[rIndex];
                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(Icons.subdirectory_arrow_right, size: 14, color: AppColors.otherText),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  reply['username']?.toString() ?? 'Unknown',
                                                                  style: const TextStyle(
                                                                    color: AppColors.lightNavy,
                                                                    fontWeight: FontWeight.w500,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  reply['created_at']?.toString().split('T')[0] ?? '',
                                                                  style: const TextStyle(
                                                                    color: AppColors.otherText,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 18),
                                                              child: Text(
                                                                reply['content']?.toString() ?? '',
                                                                style: const TextStyle(fontSize: 13),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),

                                              if (showReply)
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: const BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(color: AppColors.border),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextField(
                                                          controller: _replyControllers[obsId],
                                                          decoration: const InputDecoration(
                                                            labelText: 'Write a reply...',
                                                            isDense: true,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed: () => _addReply(obsId),
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                        ),
                                                        child: const Text('Send'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.otherText,
            ),
          ),
          const SizedBox(height: 2),
          Text(value ?? '-'),
        ],
      ),
    );
  }
}