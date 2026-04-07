import 'package:y2notes2/features/cloud_sync/domain/entities/sync_conflict.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/sync_metadata.dart';

/// Engine that detects and resolves synchronization conflicts between
/// local and remote notebook versions.
///
/// This engine implements the conflict detection logic and provides
/// automatic resolution strategies. For cases that cannot be resolved
/// automatically, it surfaces the conflict to the user via the BLoC.
class ConflictResolutionEngine {
  const ConflictResolutionEngine();

  /// Detects whether a conflict exists between local and remote versions.
  ///
  /// A conflict occurs when both the local and remote copies have been
  /// modified since the last successful sync.
  bool detectConflict(SyncMetadata metadata) {
    if (metadata.lastSyncedAt == null) return false;
    return metadata.hasConflict;
  }

  /// Creates a [SyncConflict] object from metadata and version info.
  SyncConflict createConflict({
    required SyncMetadata metadata,
    required String notebookTitle,
    int localPageCount = 0,
    int remotePageCount = 0,
    int localSizeBytes = 0,
    int remoteSizeBytes = 0,
  }) {
    return SyncConflict(
      notebookId: metadata.notebookId,
      notebookTitle: notebookTitle,
      localModifiedAt: metadata.lastModifiedLocally ?? DateTime.now(),
      remoteModifiedAt: metadata.lastModifiedRemotely ?? DateTime.now(),
      localPageCount: localPageCount,
      remotePageCount: remotePageCount,
      localSizeBytes: localSizeBytes,
      remoteSizeBytes: remoteSizeBytes,
    );
  }

  /// Suggests an automatic resolution strategy based on the conflict.
  ///
  /// Simple heuristic: if one version has significantly more content
  /// (pages), prefer that version. Otherwise default to keeping local.
  ConflictResolution suggestResolution(SyncConflict conflict) {
    // If the remote has significantly more pages, suggest keeping remote.
    if (conflict.remotePageCount > conflict.localPageCount + 2) {
      return ConflictResolution.keepRemote;
    }

    // If the local has significantly more pages, suggest keeping local.
    if (conflict.localPageCount > conflict.remotePageCount + 2) {
      return ConflictResolution.keepLocal;
    }

    // If both versions are similar in size, suggest keeping both
    // so the user doesn't lose any data.
    return ConflictResolution.keepBoth;
  }

  /// Applies the chosen resolution and returns the resulting sync direction.
  SyncDirection applyResolution(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return SyncDirection.upload;
      case ConflictResolution.keepRemote:
        return SyncDirection.download;
      case ConflictResolution.merge:
        return SyncDirection.bidirectional;
      case ConflictResolution.keepBoth:
        // Keep both means we upload a copy with a different name.
        return SyncDirection.upload;
    }
  }
}
