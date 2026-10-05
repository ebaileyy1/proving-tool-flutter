import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/services/local_db.dart';
import 'package:proving_tool/services/trial_activity_log.dart';
import 'package:proving_tool/utils/file_io.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_service.dart';

/// Reserved payload key for a queued update's base `updated_at`. SyncService
/// strips it before sending the payload to Supabase.
const kBaseUpdatedAtKey = '_baseUpdatedAt';

/// The only thing that talks to Supabase for trials. Writes go straight
/// through when online and get queued in [LocalDb] when offline or when the
/// request fails. [trials] is the synced data with queued changes laid over it.
class TrialRepository {
  TrialRepository({required this.supabase, required this.db, required this.connectivity}) {
    _pendingTrialsSub = db.select(db.pendingTrials).watch().listen((_) {
      unawaited(_recompute());
    });
    _pendingFilesSub = db.select(db.pendingFiles).watch().listen((_) {
      unawaited(_recomputeSyncSummary());
    });
  }

  final SupabaseClient supabase;
  final LocalDb db;
  final ConnectivityService connectivity;

  final _uuid = const Uuid();
  List<Map<String, dynamic>> _syncedTrials = [];

  StreamSubscription<List<PendingTrial>>? _pendingTrialsSub;
  StreamSubscription<List<PendingFile>>? _pendingFilesSub;

  final ValueNotifier<List<TrialListItem>> trials = ValueNotifier(const []);
  final ValueNotifier<SyncSummary> syncSummary = ValueNotifier(const SyncSummary());

  void dispose() {
    _pendingTrialsSub?.cancel();
    _pendingFilesSub?.cancel();
  }

  /// Re-fetches synced trials when online and rebuilds the merged list.
  Future<void> refresh() async {
    if (connectivity.isOnline.value) {
      try {
        final response = await supabase
            .from('topics')
            .select()
            .order('created_at', ascending: false);
        _syncedTrials = List<Map<String, dynamic>>.from(response as List);
      } catch (_) {
        // keep the last synced list on a flaky fetch
      }
    }
    await _recompute();
  }

  /// Fields of a not-yet-synced trial, for the local preview (no server id yet).
  Future<Map<String, dynamic>?> getLocalPendingTrialData(String localId) async {
    final row = await (db.select(
      db.pendingTrials,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null) return null;
    return _decodePayload(row.payloadJson, fallbackCreatedAt: row.createdAt);
  }

  Future<List<PendingFile>> getLocalFilesFor({String? trialLocalId, int? trialRemoteId}) {
    final query = db.select(db.pendingFiles);
    if (trialLocalId != null) {
      query.where((f) => f.trialLocalId.equals(trialLocalId));
    } else if (trialRemoteId != null) {
      query.where((f) => f.trialRemoteId.equals(trialRemoteId));
    }
    return query.get();
  }

  void markSyncCompleted(DateTime at) {
    syncSummary.value = syncSummary.value.copyWith(lastSyncedAt: at);
  }

  Future<TrialSaveResult> createTrial({
    required Map<String, dynamic> fields,
    List<PickedFileAttachment> drawings = const [],
    List<PickedFileAttachment> evidence = const [],
  }) async {
    if (connectivity.isOnline.value) {
      try {
        final response = await supabase.from('topics').insert(fields).select().single();
        final remoteId = (response['id'] as num).toInt();
        await _uploadFilesOnline(remoteId, drawings, 'drawing');
        await _uploadFilesOnline(remoteId, evidence, 'evidence');
        unawaited(
          TrialActivityLog.logCreated(supabase: supabase, topicId: remoteId, fields: fields),
        );
        await refresh();
        return TrialSaveResult(savedOnline: true, remoteId: remoteId);
      } catch (_) {
        // connectivity can go stale mid-save, so queue locally instead
      }
    }
    return _queueCreate(fields, drawings, evidence);
  }

  /// [baseUpdatedAt] is the `updated_at` the editor loaded; null skips the
  /// conflict check. Throws [TrialConflictException] rather than overwrite.
  Future<TrialSaveResult> updateTrial({
    int? remoteId,
    String? localId,
    required Map<String, dynamic> fields,
    List<PickedFileAttachment> newDrawings = const [],
    List<PickedFileAttachment> newEvidence = const [],
    String? baseUpdatedAt,
    // overrides the default activity-log line for small, specific edits
    String? activityAction,
  }) async {
    assert(remoteId != null || localId != null, 'updateTrial needs either a remoteId or a localId');

    if (localId != null) {
      await (db.update(db.pendingTrials)..where((t) => t.localId.equals(localId))).write(
        PendingTrialsCompanion(
          payloadJson: Value(jsonEncode(fields)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _queueFiles(trialLocalId: localId, files: newDrawings, category: 'drawing');
      await _queueFiles(trialLocalId: localId, files: newEvidence, category: 'evidence');
      return TrialSaveResult(savedOnline: false, localId: localId);
    }

    if (connectivity.isOnline.value) {
      try {
        await _checkNotConflicted(remoteId!, baseUpdatedAt);
        await supabase.from('topics').update(fields).eq('id', remoteId);
        await _uploadFilesOnline(remoteId, newDrawings, 'drawing');
        await _uploadFilesOnline(remoteId, newEvidence, 'evidence');
        unawaited(
          TrialActivityLog.logUpdated(
            supabase: supabase,
            topicId: remoteId,
            fields: fields,
            action: activityAction,
          ),
        );
        await refresh();
        return TrialSaveResult(savedOnline: true, remoteId: remoteId);
      } on TrialConflictException {
        // queueing would just hit the same conflict later
        rethrow;
      } catch (_) {
        // fall back to the queue, same as createTrial
      }
    }
    return _queueUpdate(remoteId!, fields, newDrawings, newEvidence, baseUpdatedAt);
  }

  // conflict check compares the server's updated_at to what the editor started from
  Future<void> _checkNotConflicted(int remoteId, String? baseUpdatedAt) async {
    if (baseUpdatedAt == null) return;
    final row = await supabase.from('topics').select('updated_at').eq('id', remoteId).maybeSingle();
    final currentUpdatedAt = row?['updated_at']?.toString();
    if (currentUpdatedAt != null && currentUpdatedAt != baseUpdatedAt) {
      throw TrialConflictException(currentUpdatedAt);
    }
  }

  Future<TrialSaveResult> attachFile({
    int? remoteId,
    String? localId,
    required PickedFileAttachment file,
    required String category,
  }) async {
    assert(remoteId != null || localId != null, 'attachFile needs either a remoteId or a localId');

    if (remoteId != null) {
      if (connectivity.isOnline.value) {
        try {
          await _uploadFileOnline(remoteId, file, category);
          await refresh();
          return TrialSaveResult(savedOnline: true, remoteId: remoteId);
        } catch (_) {
          // fall through to the queue
        }
      }
      await _queueFiles(trialRemoteId: remoteId, files: [file], category: category);
      return TrialSaveResult(savedOnline: false, remoteId: remoteId);
    }

    await _queueFiles(trialLocalId: localId, files: [file], category: category);
    return TrialSaveResult(savedOnline: false, localId: localId);
  }

  /// Online-only on purpose; throws [OfflineUnsupportedException] offline.
  Future<void> deleteTrial(int remoteId) async {
    if (!connectivity.isOnline.value) {
      throw const OfflineUnsupportedException('Deleting a trial requires an internet connection.');
    }
    await supabase.from('topics').delete().eq('id', remoteId);
    await refresh();
  }

  /// Drops a queued create/edit and its queued files. Works offline.
  Future<void> deleteLocalPendingTrial(String localId) async {
    final files = await (db.select(
      db.pendingFiles,
    )..where((f) => f.trialLocalId.equals(localId))).get();
    for (final file in files) {
      await deleteIfExists(file.localFilePath);
    }
    await db.transaction(() async {
      await (db.delete(db.pendingFiles)..where((f) => f.trialLocalId.equals(localId))).go();
      await (db.delete(db.pendingTrials)..where((t) => t.localId.equals(localId))).go();
    });
  }

  /// Drops a single queued file.
  Future<void> discardPendingFile(String id) async {
    final row = await (db.select(db.pendingFiles)..where((f) => f.id.equals(id))).getSingleOrNull();
    if (row != null) await deleteIfExists(row.localFilePath);
    await (db.delete(db.pendingFiles)..where((f) => f.id.equals(id))).go();
  }

  Future<TrialSaveResult> _queueCreate(
    Map<String, dynamic> fields,
    List<PickedFileAttachment> drawings,
    List<PickedFileAttachment> evidence,
  ) async {
    final localId = _uuid.v4();
    final now = DateTime.now();
    await db
        .into(db.pendingTrials)
        .insert(
          PendingTrialsCompanion.insert(
            localId: localId,
            operation: 'create',
            payloadJson: jsonEncode(fields),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _queueFiles(trialLocalId: localId, files: drawings, category: 'drawing');
    await _queueFiles(trialLocalId: localId, files: evidence, category: 'evidence');
    return TrialSaveResult(savedOnline: false, localId: localId);
  }

  Future<TrialSaveResult> _queueUpdate(
    int remoteId,
    Map<String, dynamic> fields,
    List<PickedFileAttachment> drawings,
    List<PickedFileAttachment> evidence,
    String? baseUpdatedAt,
  ) async {
    final now = DateTime.now();
    final existing = await (db.select(
      db.pendingTrials,
    )..where((t) => t.remoteId.equals(remoteId) & t.operation.equals('update'))).getSingleOrNull();

    // merge onto the queued payload so two offline edits don't drop the first
    final existingPayload = existing == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(existing.payloadJson) as Map);
    final existingBaseUpdatedAt = existingPayload.remove(kBaseUpdatedAtKey) as String?;
    final payload = {
      ...existingPayload,
      ...fields,
      kBaseUpdatedAtKey: ?(baseUpdatedAt ?? existingBaseUpdatedAt),
    };

    if (existing != null) {
      await (db.update(db.pendingTrials)..where((t) => t.localId.equals(existing.localId))).write(
        PendingTrialsCompanion(
          payloadJson: Value(jsonEncode(payload)),
          syncStatus: const Value(SyncStatus.pending),
          errorMessage: const Value(null),
          updatedAt: Value(now),
        ),
      );
    } else {
      await db
          .into(db.pendingTrials)
          .insert(
            PendingTrialsCompanion.insert(
              localId: _uuid.v4(),
              remoteId: Value(remoteId),
              operation: 'update',
              payloadJson: jsonEncode(payload),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    await _queueFiles(trialRemoteId: remoteId, files: drawings, category: 'drawing');
    await _queueFiles(trialRemoteId: remoteId, files: evidence, category: 'evidence');
    return TrialSaveResult(savedOnline: false, remoteId: remoteId);
  }

  Future<void> _queueFiles({
    String? trialLocalId,
    int? trialRemoteId,
    required List<PickedFileAttachment> files,
    required String category,
  }) async {
    for (final file in files) {
      final path = await _persistBytes(file);
      await db
          .into(db.pendingFiles)
          .insert(
            PendingFilesCompanion.insert(
              id: _uuid.v4(),
              trialLocalId: Value(trialLocalId),
              trialRemoteId: Value(trialRemoteId),
              category: category,
              originalName: file.name,
              mimeType: Value(mimeTypeForExtension(file.extension)),
              localFilePath: path,
              fileSizeBytes: file.sizeBytes,
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  Future<String> _persistBytes(PickedFileAttachment file) async {
    final dir = await getApplicationSupportDirectory();
    final pendingDir = Directory(p.join(dir.path, 'pending_uploads'));
    await pendingDir.create(recursive: true);
    final path = p.join(pendingDir.path, '${_uuid.v4()}_${file.name}');
    await File(path).writeAsBytes(file.bytes, flush: true);
    return path;
  }

  Future<void> _uploadFilesOnline(
    int remoteId,
    List<PickedFileAttachment> files,
    String category,
  ) async {
    for (final file in files) {
      try {
        await _uploadFileOnline(remoteId, file, category);
      } catch (_) {
        // trial is already saved, so queue this file for sync
        await _queueFiles(trialRemoteId: remoteId, files: [file], category: category);
      }
    }
  }

  Future<void> _uploadFileOnline(int remoteId, PickedFileAttachment file, String category) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final storagePath = '$remoteId/$fileName';
    await supabase.storage
        .from('trial-files')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(file.bytes),
          fileOptions: FileOptions(contentType: mimeTypeForExtension(file.extension)),
        );
    await supabase.from('files').insert({
      'topic_id': remoteId,
      'original_name': file.name,
      'storage_path': storagePath,
      'file_category': category,
    });
  }

  Map<String, dynamic> _decodePayload(String payloadJson, {required DateTime fallbackCreatedAt}) {
    final data = Map<String, dynamic>.from(jsonDecode(payloadJson) as Map);
    data.putIfAbsent('created_at', () => fallbackCreatedAt.toIso8601String());
    return data;
  }

  Future<void> _recompute() async {
    final pendingRows = await db.select(db.pendingTrials).get();

    final updatesByRemoteId = <int, PendingTrial>{
      for (final row in pendingRows)
        if (row.operation == 'update' && row.remoteId != null) row.remoteId!: row,
    };

    final items = <TrialListItem>[
      for (final row in pendingRows.where((r) => r.operation == 'create'))
        TrialListItem(
          data: _decodePayload(row.payloadJson, fallbackCreatedAt: row.createdAt),
          isPending: true,
          hasSyncError: row.syncStatus == SyncStatus.error,
          errorMessage: row.errorMessage,
          localId: row.localId,
        ),
      for (final synced in _syncedTrials)
        if (updatesByRemoteId[(synced['id'] as num?)?.toInt()] case final update?)
          TrialListItem(
            data: {...synced, ...jsonDecode(update.payloadJson) as Map<String, dynamic>},
            isPending: true,
            hasSyncError: update.syncStatus == SyncStatus.error,
            errorMessage: update.errorMessage,
          )
        else
          TrialListItem(data: synced),
    ];

    items.sort((a, b) {
      final aDate = DateTime.tryParse(a.data['created_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b.data['created_at']?.toString() ?? '');
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    trials.value = items;
    await _recomputeSyncSummary();
  }

  Future<void> _recomputeSyncSummary() async {
    final trialRows = await db.select(db.pendingTrials).get();
    final fileRows = await db.select(db.pendingFiles).get();

    var pending = 0, syncing = 0, error = 0;
    for (final status in [
      ...trialRows.map((t) => t.syncStatus),
      ...fileRows.map((f) => f.uploadStatus),
    ]) {
      switch (status) {
        case SyncStatus.syncing:
          syncing++;
        case SyncStatus.error:
          error++;
        default:
          pending++;
      }
    }

    syncSummary.value = syncSummary.value.copyWith(
      pendingCount: pending,
      syncingCount: syncing,
      errorCount: error,
    );
  }
}
