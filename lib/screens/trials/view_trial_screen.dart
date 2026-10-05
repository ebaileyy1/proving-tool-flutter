import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/trials/add_trial_screen.dart';
import 'package:proving_tool/screens/trials/edit_trial_screen.dart';
import 'package:proving_tool/screens/trials/view_trial/discussion_tab.dart';
import 'package:proving_tool/screens/trials/view_trial/enabling_tab.dart';
import 'package:proving_tool/screens/trials/view_trial/files_tab.dart';
import 'package:proving_tool/screens/trials/view_trial/overview_tab.dart';
import 'package:proving_tool/screens/trials/view_trial/trial_banners.dart';
import 'package:proving_tool/screens/pdf/trial_pdf.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/services/notification_service.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/utils/enabling_checklist.dart';
import 'package:proving_tool/utils/file_picker_helper.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/add_outcome_sheet.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/pending_sync_chip.dart';
import 'package:proving_tool/widgets/trial_date_picker.dart';
import 'package:proving_tool/widgets/trial_form.dart' show tripCountsByDay;

class ViewTrialScreen extends StatefulWidget {
  final TrialListItem item;

  const ViewTrialScreen({super.key, required this.item});

  @override
  State<ViewTrialScreen> createState() => _ViewTrialScreenState();
}

class _ViewTrialScreenState extends State<ViewTrialScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final TrialRepository _repo;
  late final ConnectivityService _connectivity;
  late final TabController _tabController;
  bool _repoInitialized = false;
  final _drafts = DiscussionDrafts();
  Map<String, dynamic> _trial = {};
  List<Map<String, dynamic>> _observations = [];
  Map<int, List<Map<String, dynamic>>> _replies = {};
  List<Map<String, dynamic>> _files = [];
  List<Map<String, dynamic>> _drawings = [];
  List<Map<String, dynamic>> _evidenceFiles = [];
  List<Map<String, dynamic>> _activity = [];
  Map<String, String> _usernamesById = {};
  bool _isLoading = true;
  bool _isUploadingDrawing = false;
  bool _isUploadingEvidence = false;
  bool _isOwnerOrAdmin = false;
  bool _isExportingPdf = false;
  bool _isDownloadingAll = false;

  // No server id yet, so observations, PDF export and delete wait until it syncs.
  bool get _isPendingLocal => widget.item.localId != null;

  int? get _remoteId => widget.item.remoteId;

  // Uses the planned completion date only, no fallback to start date. No
  // completion date means it's never due.
  bool get _needsOutcome {
    final status = _trial['status_of_trial']?.toString();
    if (status != 'Pending' && status != 'In Progress') return false;
    final date = DateTime.tryParse(_trial['date_of_completion']?.toString() ?? '');
    if (date == null) return false;
    return !dateOnly(date).isAfter(dateOnly(DateTime.now()));
  }

  @override
  void initState() {
    super.initState();
    _trial = Map<String, dynamic>.from(widget.item.data);
    _tabController = TabController(length: 4, vsync: this);
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
    showMessage(context, message);
    return false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _drafts.dispose();
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
      final pendingFiles = await _repo.getLocalFilesFor(trialLocalId: widget.item.localId);
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
      final trialData = await _supabase.from('topics').select().eq('id', _remoteId!).single();

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

      final profiles = await _supabase.from('profiles').select('is_admin').eq('id', userId);

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

      // log_of_activity is admin-read only (RLS), so non-admins get an empty list.
      // Separate try so it can't break loading the rest of the trial.
      var activityList = <Map<String, dynamic>>[];
      var usernamesById = <String, String>{};
      try {
        final activityRows = await _supabase
            .from('log_of_activity')
            .select()
            .eq('topic_id', _remoteId!)
            .order('logged_at', ascending: false);
        activityList = List<Map<String, dynamic>>.from(activityRows);

        final actorIds = activityList
            .map((a) => a['user_id']?.toString())
            .whereType<String>()
            .toSet();
        if (actorIds.isNotEmpty) {
          final actorProfiles = await _supabase
              .from('profiles')
              .select('id, username')
              .inFilter('id', actorIds.toList());
          for (final p in actorProfiles) {
            usernamesById[p['id'].toString()] = p['username']?.toString() ?? 'Unknown';
          }
        }
      } catch (e) {
        logError('Error loading trial activity log', e);
      }

      setState(() {
        _trial = Map<String, dynamic>.from(trialData);
        _observations = List<Map<String, dynamic>>.from(observations);
        _files = allFilesList;
        _drawings = allFilesList.where((f) => f['file_category'] == 'drawing').toList();
        _evidenceFiles = allFilesList.where((f) => f['file_category'] != 'drawing').toList();
        _replies = repliesMap;
        _activity = activityList;
        _usernamesById = usernamesById;
        _isOwnerOrAdmin = trialData['posted_by'] == userId || isAdmin;
      });
    } catch (e) {
      logError('Error loading data', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addObservation() async {
    if (_drafts.observationController.text.trim().isEmpty) return;
    if (!_requireOnline('Adding an observation needs an internet connection.')) {
      return;
    }
    try {
      await _supabase.from('observations').insert({
        'topic_id': _remoteId,
        'posted_by': _supabase.auth.currentUser!.id,
        'content': _drafts.observationController.text.trim(),
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

      _drafts.observationController.clear();
      _loadData();
    } catch (e) {
      logError('Error adding observation', e);
      if (mounted) {
        showMessage(context, 'Error adding observation: $e');
      }
    }
  }

  Future<void> _addReply(int observationId) async {
    final controller = _drafts.replyControllers[observationId];
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
      setState(() => _drafts.showReplyBox[observationId] = false);
      _loadData();
    } catch (e) {
      logError('Error adding reply', e);
      if (mounted) {
        showMessage(context, 'Error adding reply: $e');
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
        supabase: _supabase,
      );
    } catch (e) {
      logError('Error generating PDF', e);
      if (mounted) {
        showMessage(context, 'Error generating PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  bool _enablingFlag(String key) => _trial[key] == true;

  // enabling_notes is a decoded jsonb Map, or missing on older trials.
  Map<String, String> get _enablingReasons {
    final raw = _trial['enabling_notes'];
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  // Permits need a 14 day lead time.
  DateTime get _permitsMinDate {
    if (!_enablingFlag(kEnablingPermitsRequired)) return DateTime(2020);
    return dateOnly(DateTime.now()).add(const Duration(days: 14));
  }

  DateTime get _endDateMinDate {
    final start = DateTime.tryParse(_trial['date_of_start']?.toString() ?? '');
    final permitsMin = _permitsMinDate;
    if (start == null) return permitsMin;
    final startOnly = dateOnly(start);
    return startOnly.isAfter(permitsMin) ? startOnly : permitsMin;
  }

  Future<void> _pickTrialDate({required bool isStart}) async {
    final field = isStart ? 'date_of_start' : 'date_of_completion';
    final minDate = isStart ? _permitsMinDate : _endDateMinDate;
    final current = DateTime.tryParse(_trial[field]?.toString() ?? '');
    final initial = (current != null && !current.isBefore(minDate)) ? current : minDate;

    final picked = await showTrialDatePicker(
      context: context,
      initialDate: initial,
      minDate: minDate,
      maxDate: DateTime(2030),
      countsByDay: tripCountsByDay(context),
    );
    if (picked == null) return;

    await _saveField(
      field,
      picked.toIso8601String(),
      isStart ? 'updated the Start Date' : 'updated the End Date',
      'Error updating trial date',
    );
  }

  // Saves one field right away. Reverts the local value and tells the user if the save fails.
  Future<void> _saveField(
    String field,
    Object value,
    String activityAction,
    String logLabel, {
    bool announce = true,
  }) async {
    final previous = _trial[field];
    setState(() => _trial[field] = value);
    try {
      final result = await _repo.updateTrial(
        remoteId: _remoteId,
        fields: {field: value},
        activityAction: activityAction,
      );
      if (announce && mounted) {
        showMessage(
          context,
          result.savedOnline ? 'Saved' : "Saved - will sync when you're back online",
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      logError(logLabel, e);
      if (mounted) {
        setState(() => _trial[field] = previous);
        showMessage(context, "Couldn't save that change - please try again.");
      }
    }
  }

  // Only Proving Scripts gates status; the other items are tracking only.
  bool get _isEnablingComplete => isEnablingItemSatisfied(
    checked: _enablingFlag(kEnablingProvingScripts),
    field: kEnablingProvingScripts,
    reasons: _enablingReasons,
  );

  Future<void> _toggleEnabling(String field, bool value) =>
      _saveField(field, value, enablingActivityLabel(field), 'Error updating enabling checklist');

  Future<void> _setEnablingReason(String field, String value) => _saveField(
    'enabling_notes',
    {..._enablingReasons, field: value},
    enablingActivityLabel(field),
    'Error saving enabling reason',
    announce: false,
  );

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
        showMessage(
          context,
          result.savedOnline
              ? '${category == 'drawing' ? 'Drawing' : 'Evidence file'} uploaded successfully'
              : "Saved - will upload when you're back online",
        );
      }
      _loadData();
    } catch (e) {
      logError('Error uploading file', e);
      if (mounted) {
        showMessage(context, 'Error uploading: $e');
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
      // trial-files is a private bucket, so download via a signed URL.
      final url = await _supabase.storage
          .from('trial-files')
          .createSignedUrl(file['storage_path'], 300);

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          showMessage(context, 'Could not open file');
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
    if (!_isPendingLocal && !_requireOnline('Deleting a trial requires an internet connection.')) {
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
          showMessage(context, 'Error deleting trial: $e');
        }
      }
    }
  }

  Future<void> _addOutcome() async {
    final saved = await showAddOutcomeSheet(context, widget.item);
    if (saved == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final status = _trial['status_of_trial']?.toString() ?? '';
    final isPostTrial = status == 'Completed' || status == 'Failed';
    final fileCount = _drawings.length + _evidenceFiles.length;

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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => AddTrialScreen(prefill: _trial)));
            },
          ),
          if (_isOwnerOrAdmin) ...[
            HeaderIconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditTrialScreen(trial: _trial, localId: widget.item.localId),
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
          : Column(
              children: [
                if (_isPendingLocal) const PendingSyncBanner(),
                if (_needsOutcome) NeedsOutcomeBanner(onAddOutcome: _addOutcome),
                Material(
                  color: AppColors.background,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.navy,
                    unselectedLabelColor: AppColors.otherText,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    tabs: [
                      const Tab(text: 'Overview'),
                      Tab(text: _isEnablingComplete ? 'Enabling' : 'Enabling ⚠'),
                      Tab(text: fileCount == 0 ? 'Files' : 'Files ($fileCount)'),
                      Tab(
                        text: _observations.isEmpty
                            ? 'Discussion'
                            : 'Discussion (${_observations.length})',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      OverviewTab(
                        trial: _trial,
                        status: status,
                        isPostTrial: isPostTrial,
                        isPendingLocal: _isPendingLocal,
                        activity: _activity,
                        usernamesById: _usernamesById,
                        onPickDate: (isStart) => _pickTrialDate(isStart: isStart),
                      ),
                      EnablingTab(
                        isChecked: _enablingFlag,
                        reasons: _enablingReasons,
                        isComplete: _isEnablingComplete,
                        isPendingLocal: _isPendingLocal,
                        onToggle: _toggleEnabling,
                        onSetReason: _setEnablingReason,
                      ),
                      FilesTab(
                        drawings: _drawings,
                        evidenceFiles: _evidenceFiles,
                        isPostTrial: isPostTrial,
                        isPendingLocal: _isPendingLocal,
                        isOwnerOrAdmin: _isOwnerOrAdmin,
                        isUploadingDrawing: _isUploadingDrawing,
                        isUploadingEvidence: _isUploadingEvidence,
                        isDownloadingAll: _isDownloadingAll,
                        actions: TrialFileActions(
                          onUpload: _uploadFile,
                          onDownload: _downloadFile,
                          onDownloadAll: _downloadAllFiles,
                        ),
                      ),
                      DiscussionTab(
                        isPendingLocal: _isPendingLocal,
                        observations: _observations,
                        replies: _replies,
                        drafts: _drafts,
                        onAddObservation: _addObservation,
                        onAddReply: _addReply,
                        onToggleReply: (observationId) => setState(() {
                          _drafts.showReplyBox[observationId] =
                              !(_drafts.showReplyBox[observationId] ?? false);
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
