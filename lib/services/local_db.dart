import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_db.g.dart';

/// Sync status values shared by [PendingTrials] and [PendingFiles].
class SyncStatus {
  static const pending = 'pending';
  static const syncing = 'syncing';
  static const synced = 'synced';
  static const error = 'error';
}

/// A trial that was created or edited while offline (or that failed to sync
/// yet) and needs to be pushed to Supabase. `payloadJson` is the exact map
/// that would otherwise have been passed straight to `.insert()`/`.update()`
/// so the outbox never needs to know about individual trial fields.
class PendingTrials extends Table {
  TextColumn get localId => text()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get operation => text()(); // 'create' | 'update'
  TextColumn get payloadJson => text()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant(SyncStatus.pending))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

/// A drawing/evidence file attached to a trial that hasn't been uploaded to
/// Supabase Storage yet. Exactly one of [trialLocalId]/[trialRemoteId] is
/// set at any given time.
class PendingFiles extends Table {
  TextColumn get id => text()();
  TextColumn get trialLocalId => text().nullable()();
  IntColumn get trialRemoteId => integer().nullable()();
  TextColumn get category => text()(); // 'drawing' | 'evidence'
  TextColumn get originalName => text()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get localFilePath => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get uploadStatus =>
      text().withDefault(const Constant(SyncStatus.pending))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [PendingTrials, PendingFiles])
class LocalDb extends _$LocalDb {
  LocalDb._(super.executor);

  static LocalDb? _instance;

  factory LocalDb() => _instance ??= LocalDb._(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
  );

  /// Rows can be left stuck in `syncing`/`uploading` if the app is killed
  /// mid-sync. Call once at startup so a crash doesn't permanently wedge an
  /// item — it just falls back to being retried like any other pending item.
  Future<void> resetInterruptedSyncStatus() async {
    await (update(pendingTrials)
          ..where((t) => t.syncStatus.equals(SyncStatus.syncing)))
        .write(const PendingTrialsCompanion(
      syncStatus: Value(SyncStatus.pending),
    ));
    await (update(pendingFiles)
          ..where((f) => f.uploadStatus.equals(SyncStatus.syncing)))
        .write(const PendingFilesCompanion(
      uploadStatus: Value(SyncStatus.pending),
    ));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'proving_tool_outbox.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
