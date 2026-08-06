import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connectivity_service.dart';
import 'local_db.dart';
import 'trial_repository.dart';

/// Walks the local outbox and pushes queued trials/files to Supabase
/// whenever connectivity is restored, the app resumes, or the user taps
/// "Sync now". Safe to trigger repeatedly/concurrently — an in-flight pass
/// absorbs later triggers instead of running twice.
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

  /// Runs one (or more, if new writes land mid-pass) sync pass. A manual
  /// call re-probes connectivity first since the user is explicitly asking
  /// "try now" rather than relying on the last background check.
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

  // ---------------------------------------------------------------------
  // Trials
  // ---------------------------------------------------------------------

  Future<void> _syncTrials() async {
    final rows =
        await (db.select(db.pendingTrials)
              ..where(
                (t) =>
                    t.syncStatus.equals(SyncStatus.pending) |
                    t.syncStatus.equals(SyncStatus.error),
              )
              // 'create' sorts before 'update' alphabetically, which
              // conveniently matches the order a trial's id must exist in
              // before any update or file-attach can target it.
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
    await (db.update(
      db.pendingTrials,
    )..where((t) => t.localId.equals(row.localId))).write(
      const PendingTrialsCompanion(syncStatus: Value(SyncStatus.syncing)),
    );

    try {
      final fields = Map<String, dynamic>.from(
        jsonDecode(row.payloadJson) as Map,
      );
      final remoteId = row.operation == 'create'
          ? await _createRemoteTrial(fields, row.localId)
          : await _updateRemoteTrial(row.remoteId!, fields);

      await db.transaction(() async {
        await (db.update(
          db.pendingFiles,
        )..where((f) => f.trialLocalId.equals(row.localId))).write(
          PendingFilesCompanion(
            trialLocalId: const Value(null),
            trialRemoteId: Value(remoteId),
          ),
        );
        await (db.delete(
          db.pendingTrials,
        )..where((t) => t.localId.equals(row.localId))).go();
      });
    } catch (e) {
      await (db.update(
        db.pendingTrials,
      )..where((t) => t.localId.equals(row.localId))).write(
        PendingTrialsCompanion(
          syncStatus: const Value(SyncStatus.error),
          errorMessage: Value(e.toString()),
        ),
      );
    }
  }

  /// Uses `client_uuid` to detect a create that already landed on a prior
  /// attempt (e.g. the app was killed after the insert succeeded but before
  /// the local row could be marked synced), so retrying never duplicates
  /// the trial.
  Future<int> _createRemoteTrial(
    Map<String, dynamic> fields,
    String localId,
  ) async {
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
  ) async {
    await supabase.from('topics').update(fields).eq('id', remoteId);
    return remoteId;
  }

  // ---------------------------------------------------------------------
  // Files
  // ---------------------------------------------------------------------

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
    await (db.update(
      db.pendingFiles,
    )..where((f) => f.id.equals(row.id))).write(
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
              contentType:
                  row.mimeType ??
                  mimeTypeForExtension(extensionOf(row.originalName)),
              upsert: true,
            ),
          );

      await supabase.from('files').insert({
        'topic_id': row.trialRemoteId,
        'original_name': row.originalName,
        'storage_path': storagePath,
        'file_category': row.category,
      });

      await (db.delete(
        db.pendingFiles,
      )..where((f) => f.id.equals(row.id))).go();

      final onDisk = File(row.localFilePath);
      if (await onDisk.exists()) {
        await onDisk.delete();
      }
    } catch (e) {
      await (db.update(
        db.pendingFiles,
      )..where((f) => f.id.equals(row.id))).write(
        PendingFilesCompanion(
          uploadStatus: const Value(SyncStatus.error),
          errorMessage: Value(e.toString()),
        ),
      );
    }
  }
}
