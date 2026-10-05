import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/services/trial_activity_log.dart';
import 'package:proving_tool/utils/file_io.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connectivity_service.dart';
import 'local_db.dart';
import 'trial_repository.dart';

/// Pushes queued trials and files to Supabase when connectivity returns, the
/// app resumes, or the user taps Sync now. Safe to call repeatedly.
class SyncService with WidgetsBindingObserver {
  SyncService({
    required this.supabase,
    required this.db,
    required this.connectivity,
    required this.trialRepository,
  });

  final SupabaseClient supabase;
  final LocalDb db;
  final ConnectivityService connectivity;
  final TrialRepository trialRepository;

  bool _isSyncing = false;
  bool _rerunRequested = false;
  bool _wasOnline = true;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _wasOnline = connectivity.isOnline.value;
    connectivity.isOnline.addListener(_onConnectivityChanged);
    if (_wasOnline) {
      unawaited(syncNow());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    connectivity.isOnline.removeListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    final isOnlineNow = connectivity.isOnline.value;
    if (!_wasOnline && isOnlineNow) {
      unawaited(syncNow());
    }
    _wasOnline = isOnlineNow;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && connectivity.isOnline.value) {
      unawaited(syncNow());
    }
  }

  /// Runs a sync pass; calls during a pass just queue one more rerun.
  /// A manual call re-probes connectivity first.
  Future<void> syncNow({bool manual = false}) async {
    if (_isSyncing) {
      _rerunRequested = true;
      return;
    }
    _isSyncing = true;
    try {
      var ranAnyPass = false;
      do {
        _rerunRequested = false;
        if (manual) {
          await connectivity.checkNow();
        }
        if (!connectivity.isOnline.value) break;
        await _syncTrials();
        await _syncFiles();
        ranAnyPass = true;
      } while (_rerunRequested);

      if (ranAnyPass) {
        trialRepository.markSyncCompleted(DateTime.now());
      }
    } finally {
      _isSyncing = false;
    }
    await trialRepository.refresh();
  }

  Future<void> _syncTrials() async {
    final rows =
        await (db.select(db.pendingTrials)
              ..where(
                (t) =>
                    t.syncStatus.equals(SyncStatus.pending) | t.syncStatus.equals(SyncStatus.error),
              )
              // 'create' sorts before 'update', which is the order we need
              ..orderBy([
                (t) => OrderingTerm(expression: t.operation),
                (t) => OrderingTerm(expression: t.createdAt),
              ]))
            .get();

    for (final row in rows) {
      await _syncOneTrial(row);
    }
  }

  Future<void> _syncOneTrial(PendingTrial row) async {
    await (db.update(db.pendingTrials)..where((t) => t.localId.equals(row.localId))).write(
      const PendingTrialsCompanion(syncStatus: Value(SyncStatus.syncing)),
    );

    try {
      final fields = Map<String, dynamic>.from(jsonDecode(row.payloadJson) as Map);
      // reserved key on queued updates, not a real trial field
      final baseUpdatedAt = fields.remove(kBaseUpdatedAtKey) as String?;
      final remoteId = row.operation == 'create'
          ? await _createRemoteTrial(fields, row.localId)
          : await _updateRemoteTrial(row.remoteId!, fields, baseUpdatedAt);

      unawaited(
        row.operation == 'create'
            ? TrialActivityLog.logCreated(supabase: supabase, topicId: remoteId, fields: fields)
            : TrialActivityLog.logUpdated(supabase: supabase, topicId: remoteId, fields: fields),
      );

      await db.transaction(() async {
        await (db.update(db.pendingFiles)..where((f) => f.trialLocalId.equals(row.localId))).write(
          PendingFilesCompanion(trialLocalId: const Value(null), trialRemoteId: Value(remoteId)),
        );
        await (db.delete(db.pendingTrials)..where((t) => t.localId.equals(row.localId))).go();
      });
    } catch (e) {
      await (db.update(db.pendingTrials)..where((t) => t.localId.equals(row.localId))).write(
        PendingTrialsCompanion(
          syncStatus: const Value(SyncStatus.error),
          errorMessage: Value(e.toString()),
        ),
      );
    }
  }

  // the client_uuid check makes a retried create idempotent
  Future<int> _createRemoteTrial(Map<String, dynamic> fields, String localId) async {
    final existing = await supabase
        .from('topics')
        .select('id')
        .eq('client_uuid', localId)
        .maybeSingle();
    if (existing != null) {
      return (existing['id'] as num).toInt();
    }
    final response = await supabase
        .from('topics')
        .insert({...fields, 'client_uuid': localId})
        .select()
        .single();
    return (response['id'] as num).toInt();
  }

  Future<int> _updateRemoteTrial(
    int remoteId,
    Map<String, dynamic> fields,
    String? baseUpdatedAt,
  ) async {
    if (baseUpdatedAt != null) {
      final row = await supabase
          .from('topics')
          .select('updated_at')
          .eq('id', remoteId)
          .maybeSingle();
      final currentUpdatedAt = row?['updated_at']?.toString();
      if (currentUpdatedAt != null && currentUpdatedAt != baseUpdatedAt) {
        // _syncOneTrial turns this into a sync error shown on Pending Uploads
        throw TrialConflictException(currentUpdatedAt);
      }
    }
    await supabase.from('topics').update(fields).eq('id', remoteId);
    return remoteId;
  }

  Future<void> _syncFiles() async {
    final rows =
        await (db.select(db.pendingFiles)..where(
              (f) =>
                  (f.uploadStatus.equals(SyncStatus.pending) |
                      f.uploadStatus.equals(SyncStatus.error)) &
                  f.trialRemoteId.isNotNull(),
            ))
            .get();

    for (final row in rows) {
      await _syncOneFile(row);
    }
  }

  Future<void> _syncOneFile(PendingFile row) async {
    await (db.update(db.pendingFiles)..where((f) => f.id.equals(row.id))).write(
      const PendingFilesCompanion(uploadStatus: Value(SyncStatus.syncing)),
    );

    try {
      final bytes = await File(row.localFilePath).readAsBytes();
      final storagePath =
          '${row.trialRemoteId}/${DateTime.now().millisecondsSinceEpoch}_${row.originalName}';

      await supabase.storage
          .from('trial-files')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: row.mimeType ?? mimeTypeForExtension(extensionOf(row.originalName)),
              upsert: true,
            ),
          );

      await supabase.from('files').insert({
        'topic_id': row.trialRemoteId,
        'original_name': row.originalName,
        'storage_path': storagePath,
        'file_category': row.category,
      });

      await (db.delete(db.pendingFiles)..where((f) => f.id.equals(row.id))).go();

      await deleteIfExists(row.localFilePath);
    } catch (e) {
      await (db.update(db.pendingFiles)..where((f) => f.id.equals(row.id))).write(
        PendingFilesCompanion(
          uploadStatus: const Value(SyncStatus.error),
          errorMessage: Value(e.toString()),
        ),
      );
    }
  }
}
