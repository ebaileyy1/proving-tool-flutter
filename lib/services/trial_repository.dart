import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/services/local_db.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_service.dart';

/// Single seam every trial screen goes through for trial CRUD + file
/// attachment, instead of calling Supabase directly. Writes go straight to
/// Supabase when online; when offline (or when an online write fails
/// partway through), they're queued in [LocalDb] for [SyncService] to push
/// later. [trials] always reflects the last successful Supabase fetch
/// overlaid with whatever is still queued, so list screens render one
/// merged, always-up-to-date list.
class TrialRepository {
  TrialRepository({
    required this.supabase,
    required this.db,
    required this.connectivity,
  }) {
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
  final ValueNotifier<SyncSummary> syncSummary = ValueNotifier(
    const SyncSummary(),
  );

  void dispose() {
    _pendingTrialsSub?.cancel();
    _pendingFilesSub?.cancel();
  }

  // ---------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------

  /// Re-fetches synced trials from Supabase (if online) and recomputes the
  /// merged list. Call on screen init and pull-to-refresh.
  Future<void> refresh() async {
    if (connectivity.isOnline.value) {
      try {
        final response = await supabase
            .from('topics')
            .select()
            .order('created_at', ascending: false);
        _syncedTrials = List<Map<String, dynamic>>.from(response as List);
      } catch (_) {
        // Keep the last known synced list rather than blanking the screen
        // on a flaky fetch.
      }
    }
    await _recompute();
  }

  /// The raw fields of a still-unsynced trial, for a read-only local
  /// preview (it has no server id yet, so it can't be fetched normally).
  Future<Map<String, dynamic>?> getLocalPendingTrialData(
    String localId,
  ) async {
    final row = await (db.select(
      db.pendingTrials,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null) return null;
    return _decodePayload(row.payloadJson, fallbackCreatedAt: row.createdAt);
  }

  Future<List<PendingFile>> getLocalFilesFor({
    String? trialLocalId,
    int? trialRemoteId,
  }) {
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

  // ---------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------

  Future<TrialSaveResult> createTrial({
    required Map<String, dynamic> fields,
    List<PickedFileAttachment> drawings = const [],
    List<PickedFileAttachment> evidence = const [],
  }) async {
    if (connectivity.isOnline.value) {
      try {
        final response = await supabase
            .from('topics')
            .insert(fields)
            .select()
            .single();
        final remoteId = (response['id'] as num).toInt();
        await _uploadFilesOnline(remoteId, drawings, 'drawing');
        await _uploadFilesOnline(remoteId, evidence, 'evidence');
        await refresh();
        return TrialSaveResult(savedOnline: true, remoteId: remoteId);
      } catch (_) {
        // The connectivity check can go stale between the check and the
        // request (e.g. the connection drops mid-save). Fall back to
        // queueing locally rather than losing what the user entered.
      }
    }
    return _queueCreate(fields, drawings, evidence);
  }

  Future<TrialSaveResult> updateTrial({
    int? remoteId,
    String? localId,
    required Map<String, dynamic> fields,
    List<PickedFileAttachment> newDrawings = const [],
    List<PickedFileAttachment> newEvidence = const [],
  }) async {
    assert(
      remoteId != null || localId != null,
      'updateTrial needs either a remoteId or a localId',
    );

    if (localId != null) {
      await (db.update(
        db.pendingTrials,
      )..where((t) => t.localId.equals(localId))).write(
        PendingTrialsCompanion(
          payloadJson: Value(jsonEncode(fields)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _queueFiles(
        trialLocalId: localId,
        files: newDrawings,
        category: 'drawing',
      );
      await _queueFiles(
        trialLocalId: localId,
        files: newEvidence,
        category: 'evidence',
      );
      return TrialSaveResult(savedOnline: false, localId: localId);
    }

    if (connectivity.isOnline.value) {
      try {
        await supabase.from('topics').update(fields).eq('id', remoteId!);
        await _uploadFilesOnline(remoteId, newDrawings, 'drawing');
        await _uploadFilesOnline(remoteId, newEvidence, 'evidence');
        await refresh();
        return TrialSaveResult(savedOnline: true, remoteId: remoteId);
      } catch (_) {
        // Same fallback reasoning as createTrial.
      }
    }
    return _queueUpdate(remoteId!, fields, newDrawings, newEvidence);
  }

  Future<TrialSaveResult> attachFile({
    int? remoteId,
    String? localId,
    required PickedFileAttachment file,
    required String category,
  }) async {
    assert(
      remoteId != null || localId != null,
      'attachFile needs either a remoteId or a localId',
    );

    if (remoteId != null) {
      if (connectivity.isOnline.value) {
        try {
          await _uploadFileOnline(remoteId, file, category);
          await refresh();
          return TrialSaveResult(savedOnline: true, remoteId: remoteId);
        } catch (_) {
          // Fall through to queueing below.
        }
      }
      await _queueFiles(
        trialRemoteId: remoteId,
        files: [file],
        category: category,
      );
      return TrialSaveResult(savedOnline: false, remoteId: remoteId);
    }

    await _queueFiles(
      trialLocalId: localId,
      files: [file],
      category: category,
    );
    return TrialSaveResult(savedOnline: false, localId: localId);
  }

  /// Online-only: throws [OfflineUnsupportedException] otherwise.
  Future<void> deleteTrial(int remoteId) async {
    if (!connectivity.isOnline.value) {
      throw const OfflineUnsupportedException(
        'Deleting a trial requires an internet connection.',
      );
    }
    await supabase.from('topics').delete().eq('id', remoteId);
    await refresh();
  }

  /// Discards a queued trial create/edit (and, for a never-synced create,
  /// any files queued with it). There's nothing on the server to delete
  /// for a queued item, so this works offline too. Used both from the
  /// still-unsynced trial preview and the Pending Uploads screen.
  Future<void> deleteLocalPendingTrial(String localId) async {
    final files = await (db.select(
      db.pendingFiles,
    )..where((f) => f.trialLocalId.equals(localId))).get();
    for (final file in files) {
      final onDisk = File(file.localFilePath);
      if (await onDisk.exists()) {
        await onDisk.delete();
      }
    }
    await db.transaction(() async {
      await (db.delete(
        db.pendingFiles,
      )..where((f) => f.trialLocalId.equals(localId))).go();
      await (db.delete(
        db.pendingTrials,
      )..where((t) => t.localId.equals(localId))).go();
    });
  }

  /// Discards a single queued file attachment (e.g. one stuck in a
  /// persistent error state the user wants to give up on).
  Future<void> discardPendingFile(String id) async {
    final row = await (db.select(
      db.pendingFiles,
    )..where((f) => f.id.equals(id))).getSingleOrNull();
    if (row != null) {
      final onDisk = File(row.localFilePath);
      if (await onDisk.exists()) {
        await onDisk.delete();
      }
    }
    await (db.delete(db.pendingFiles)..where((f) => f.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------
  // Internal: queueing
  // ---------------------------------------------------------------------

  Future<TrialSaveResult> _queueCreate(
    Map<String, dynamic> fields,
    List<PickedFileAttachment> drawings,
    List<PickedFileAttachment> evidence,
  ) async {
    final localId = _uuid.v4();
    final now = DateTime.now();
    await db.into(db.pendingTrials).insert(
      PendingTrialsCompanion.insert(
        localId: localId,
        operation: 'create',
        payloadJson: jsonEncode(fields),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _queueFiles(
      trialLocalId: localId,
      files: drawings,
      category: 'drawing',
    );
    await _queueFiles(
      trialLocalId: localId,
      files: evidence,
      category: 'evidence',
    );
    return TrialSaveResult(savedOnline: false, localId: localId);
  }

  Future<TrialSaveResult> _queueUpdate(
    int remoteId,
    Map<String, dynamic> fields,
    List<PickedFileAttachment> drawings,
    List<PickedFileAttachment> evidence,
  ) async {
    final now = DateTime.now();
    final existing = await (db.select(db.pendingTrials)..where(
      (t) => t.remoteId.equals(remoteId) & t.operation.equals('update'),
    )).getSingleOrNull();

    if (existing != null) {
      await (db.update(
        db.pendingTrials,
      )..where((t) => t.localId.equals(existing.localId))).write(
        PendingTrialsCompanion(
          payloadJson: Value(jsonEncode(fields)),
          syncStatus: const Value(SyncStatus.pending),
          errorMessage: const Value(null),
          updatedAt: Value(now),
        ),
      );
    } else {
      await db.into(db.pendingTrials).insert(
        PendingTrialsCompanion.insert(
          localId: _uuid.v4(),
          remoteId: Value(remoteId),
          operation: 'update',
          payloadJson: jsonEncode(fields),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await _queueFiles(
      trialRemoteId: remoteId,
      files: drawings,
      category: 'drawing',
    );
    await _queueFiles(
      trialRemoteId: remoteId,
      files: evidence,
      category: 'evidence',
    );
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
      await db.into(db.pendingFiles).insert(
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

  // ---------------------------------------------------------------------
  // Internal: online uploads
  // ---------------------------------------------------------------------

  Future<void> _uploadFilesOnline(
    int remoteId,
    List<PickedFileAttachment> files,
    String category,
  ) async {
    for (final file in files) {
      try {
        await _uploadFileOnline(remoteId, file, category);
      } catch (_) {
        // The trial (and possibly other files) already saved successfully;
        // don't lose this one — queue it for the background sync engine.
        await _queueFiles(
          trialRemoteId: remoteId,
          files: [file],
          category: category,
        );
      }
    }
  }

  Future<void> _uploadFileOnline(
    int remoteId,
    PickedFileAttachment file,
    String category,
  ) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final storagePath = '$remoteId/$fileName';
    await supabase.storage
        .from('trial-files')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(file.bytes),
          fileOptions: FileOptions(
            contentType: mimeTypeForExtension(file.extension),
          ),
        );
    await supabase.from('files').insert({
      'topic_id': remoteId,
      'original_name': file.name,
      'storage_path': storagePath,
      'file_category': category,
    });
  }

  // ---------------------------------------------------------------------
  // Internal: merged list + summary
  // ---------------------------------------------------------------------

  Map<String, dynamic> _decodePayload(
    String payloadJson, {
    required DateTime fallbackCreatedAt,
  }) {
    final data = Map<String, dynamic>.from(
      jsonDecode(payloadJson) as Map,
    );
    data.putIfAbsent(
      'created_at',
      () => fallbackCreatedAt.toIso8601String(),
    );
    return data;
  }

  Future<void> _recompute() async {
    final pendingRows = await db.select(db.pendingTrials).get();

    final updatesByRemoteId = <int, PendingTrial>{
      for (final row in pendingRows)
        if (row.operation == 'update' && row.remoteId != null)
          row.remoteId!: row,
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
            data: {
              ...synced,
              ...jsonDecode(update.payloadJson) as Map<String, dynamic>,
            },
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
