import 'package:file_picker/file_picker.dart';
import 'package:proving_tool/utils/file_types.dart';

/// A picked file, so the sync layer doesn't depend on file_picker types.
class PickedFileAttachment {
  const PickedFileAttachment({required this.name, required this.bytes});

  factory PickedFileAttachment.fromPlatformFile(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null) {
      throw ArgumentError(
        'PlatformFile "${file.name}" has no in-memory bytes '
        '(pick with withData: true)',
      );
    }
    return PickedFileAttachment(name: file.name, bytes: bytes);
  }

  final String name;
  final List<int> bytes;

  int get sizeBytes => bytes.length;

  String get extension => extensionOf(name);
}

/// A trial row for list screens, either from Supabase or a local one waiting to sync.
class TrialListItem {
  const TrialListItem({
    required this.data,
    this.isPending = false,
    this.hasSyncError = false,
    this.errorMessage,
    this.localId,
  });

  final Map<String, dynamic> data;
  final bool isPending;
  final bool hasSyncError;
  final String? errorMessage;

  // Only set until the server assigns an id.
  final String? localId;

  int? get remoteId {
    final id = data['id'];
    return id == null ? null : (id as num).toInt();
  }
}

class TrialSaveResult {
  const TrialSaveResult({required this.savedOnline, this.localId, this.remoteId});

  final bool savedOnline;
  final String? localId;
  final int? remoteId;
}

class SyncSummary {
  const SyncSummary({
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.errorCount = 0,
    this.lastSyncedAt,
  });

  final int pendingCount;
  final int syncingCount;
  final int errorCount;
  final DateTime? lastSyncedAt;

  bool get hasWork => pendingCount > 0 || syncingCount > 0;
  bool get hasErrors => errorCount > 0;
  int get totalQueued => pendingCount + syncingCount + errorCount;

  SyncSummary copyWith({
    int? pendingCount,
    int? syncingCount,
    int? errorCount,
    DateTime? lastSyncedAt,
  }) {
    return SyncSummary(
      pendingCount: pendingCount ?? this.pendingCount,
      syncingCount: syncingCount ?? this.syncingCount,
      errorCount: errorCount ?? this.errorCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Thrown when an action has no offline path and the device is offline.
class OfflineUnsupportedException implements Exception {
  const OfflineUnsupportedException([this.message = 'This action needs an internet connection.']);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the server's `updated_at` has moved on since the editor loaded the trial.
class TrialConflictException implements Exception {
  const TrialConflictException(this.serverUpdatedAt);

  final String? serverUpdatedAt;

  @override
  String toString() => 'This trial was changed by someone else - review before retrying.';
}
