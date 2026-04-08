import 'package:equatable/equatable.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';

/// Status of a sync operation.
enum SyncOperationStatus {
  /// No sync operation is in progress.
  idle,

  /// Sync is currently in progress.
  syncing,

  /// Last sync completed successfully.
  success,

  /// Last sync failed with an error.
  error,

  /// Sync is paused (e.g. no network, user-paused).
  paused,

  /// Waiting for network connectivity.
  waitingForNetwork,
}

/// Direction of the last sync operation.
enum SyncDirection {
  /// Uploading local changes to cloud.
  upload,

  /// Downloading cloud changes to local.
  download,

  /// Both directions (merge).
  bidirectional,
}

/// Metadata about the last synchronization operation.
class SyncMetadata extends Equatable {
  const SyncMetadata({
    required this.notebookId,
    required this.provider,
    this.cloudFileId,
    this.lastSyncedAt,
    this.lastModifiedLocally,
    this.lastModifiedRemotely,
    this.localVersion = 0,
    this.remoteVersion = 0,
    this.syncStatus = SyncOperationStatus.idle,
    this.lastDirection = SyncDirection.bidirectional,
    this.errorMessage,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
  });

  /// ID of the notebook being synced.
  final String notebookId;

  /// Which cloud provider this metadata is for.
  final CloudProviderType provider;

  /// File or object ID in the cloud provider.
  final String? cloudFileId;

  /// When the notebook was last successfully synced.
  final DateTime? lastSyncedAt;

  /// When the local copy was last modified.
  final DateTime? lastModifiedLocally;

  /// When the remote copy was last modified.
  final DateTime? lastModifiedRemotely;

  /// Local version counter (incremented on each local save).
  final int localVersion;

  /// Remote version counter from the cloud.
  final int remoteVersion;

  /// Current sync status.
  final SyncOperationStatus syncStatus;

  /// Direction of the last sync.
  final SyncDirection lastDirection;

  /// Error message if [syncStatus] is [SyncOperationStatus.error].
  final String? errorMessage;

  /// Bytes transferred so far during sync.
  final int bytesTransferred;

  /// Total bytes to transfer during sync.
  final int totalBytes;

  /// Whether local changes exist that haven't been synced yet.
  bool get hasPendingChanges =>
      lastModifiedLocally != null &&
      (lastSyncedAt == null ||
          lastModifiedLocally!.isAfter(lastSyncedAt!));

  /// Whether a conflict exists between local and remote versions.
  bool get hasConflict =>
      lastModifiedLocally != null &&
      lastModifiedRemotely != null &&
      lastSyncedAt != null &&
      lastModifiedLocally!.isAfter(lastSyncedAt!) &&
      lastModifiedRemotely!.isAfter(lastSyncedAt!);

  /// Progress fraction [0.0, 1.0] during transfer.
  double get transferProgress =>
      totalBytes > 0 ? bytesTransferred / totalBytes : 0.0;

  SyncMetadata copyWith({
    String? cloudFileId,
    DateTime? lastSyncedAt,
    DateTime? lastModifiedLocally,
    DateTime? lastModifiedRemotely,
    int? localVersion,
    int? remoteVersion,
    SyncOperationStatus? syncStatus,
    SyncDirection? lastDirection,
    String? errorMessage,
    bool clearError = false,
    int? bytesTransferred,
    int? totalBytes,
  }) =>
      SyncMetadata(
        notebookId: notebookId,
        provider: provider,
        cloudFileId: cloudFileId ?? this.cloudFileId,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        lastModifiedLocally:
            lastModifiedLocally ?? this.lastModifiedLocally,
        lastModifiedRemotely:
            lastModifiedRemotely ?? this.lastModifiedRemotely,
        localVersion: localVersion ?? this.localVersion,
        remoteVersion: remoteVersion ?? this.remoteVersion,
        syncStatus: syncStatus ?? this.syncStatus,
        lastDirection: lastDirection ?? this.lastDirection,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        bytesTransferred: bytesTransferred ?? this.bytesTransferred,
        totalBytes: totalBytes ?? this.totalBytes,
      );

  @override
  List<Object?> get props => [
        notebookId,
        provider,
        cloudFileId,
        lastSyncedAt,
        lastModifiedLocally,
        lastModifiedRemotely,
        localVersion,
        remoteVersion,
        syncStatus,
        lastDirection,
        errorMessage,
        bytesTransferred,
        totalBytes,
      ];
}
