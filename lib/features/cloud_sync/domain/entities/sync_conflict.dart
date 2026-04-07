import 'package:equatable/equatable.dart';

/// Strategy for resolving a sync conflict.
enum ConflictResolution {
  /// Keep the local version and overwrite remote.
  keepLocal,

  /// Keep the remote version and overwrite local.
  keepRemote,

  /// Merge both versions (create a combined document).
  merge,

  /// Keep both as separate notebooks.
  keepBoth,
}

/// Represents a conflict between local and remote versions of a notebook.
class SyncConflict extends Equatable {
  const SyncConflict({
    required this.notebookId,
    required this.notebookTitle,
    required this.localModifiedAt,
    required this.remoteModifiedAt,
    this.localPageCount = 0,
    this.remotePageCount = 0,
    this.localSizeBytes = 0,
    this.remoteSizeBytes = 0,
    this.resolution,
    this.isResolved = false,
  });

  /// ID of the conflicting notebook.
  final String notebookId;

  /// Title of the conflicting notebook.
  final String notebookTitle;

  /// When the local copy was last modified.
  final DateTime localModifiedAt;

  /// When the remote copy was last modified.
  final DateTime remoteModifiedAt;

  /// Number of pages in the local version.
  final int localPageCount;

  /// Number of pages in the remote version.
  final int remotePageCount;

  /// Size of the local version in bytes.
  final int localSizeBytes;

  /// Size of the remote version in bytes.
  final int remoteSizeBytes;

  /// How the user chose to resolve the conflict (null if unresolved).
  final ConflictResolution? resolution;

  /// Whether the conflict has been resolved.
  final bool isResolved;

  /// Returns the newer version source.
  String get newerVersionLabel =>
      localModifiedAt.isAfter(remoteModifiedAt) ? 'Local' : 'Remote';

  SyncConflict copyWith({
    ConflictResolution? resolution,
    bool? isResolved,
  }) =>
      SyncConflict(
        notebookId: notebookId,
        notebookTitle: notebookTitle,
        localModifiedAt: localModifiedAt,
        remoteModifiedAt: remoteModifiedAt,
        localPageCount: localPageCount,
        remotePageCount: remotePageCount,
        localSizeBytes: localSizeBytes,
        remoteSizeBytes: remoteSizeBytes,
        resolution: resolution ?? this.resolution,
        isResolved: isResolved ?? this.isResolved,
      );

  @override
  List<Object?> get props => [
        notebookId,
        notebookTitle,
        localModifiedAt,
        remoteModifiedAt,
        localPageCount,
        remotePageCount,
        localSizeBytes,
        remoteSizeBytes,
        resolution,
        isResolved,
      ];
}
