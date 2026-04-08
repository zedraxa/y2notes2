import 'package:equatable/equatable.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/sync_conflict.dart';

/// Base class for all cloud sync events.
abstract class CloudSyncEvent extends Equatable {
  const CloudSyncEvent();

  @override
  List<Object?> get props => [];
}

// ── Provider management ────────────────────────────────────────────────────

/// Connect / authenticate with a cloud provider.
class ConnectProvider extends CloudSyncEvent {
  const ConnectProvider({required this.providerType});
  final CloudProviderType providerType;
  @override
  List<Object?> get props => [providerType];
}

/// Disconnect / sign out from a cloud provider.
class DisconnectProvider extends CloudSyncEvent {
  const DisconnectProvider({required this.providerType});
  final CloudProviderType providerType;
  @override
  List<Object?> get props => [providerType];
}

/// Set the active provider for syncing.
class SetActiveProvider extends CloudSyncEvent {
  const SetActiveProvider({required this.providerType});
  final CloudProviderType providerType;
  @override
  List<Object?> get props => [providerType];
}

// ── Sync operations ────────────────────────────────────────────────────────

/// Trigger a manual sync for the current notebook.
class SyncNow extends CloudSyncEvent {
  const SyncNow({required this.notebookId});
  final String notebookId;
  @override
  List<Object?> get props => [notebookId];
}

/// Sync all notebooks that have pending changes.
class SyncAllNotebooks extends CloudSyncEvent {
  const SyncAllNotebooks();
}

/// Upload a specific notebook to the cloud.
class UploadNotebook extends CloudSyncEvent {
  const UploadNotebook({required this.notebookId});
  final String notebookId;
  @override
  List<Object?> get props => [notebookId];
}

/// Download a specific notebook from the cloud.
class DownloadNotebook extends CloudSyncEvent {
  const DownloadNotebook({
    required this.notebookId,
    required this.cloudFileId,
  });
  final String notebookId;
  final String cloudFileId;
  @override
  List<Object?> get props => [notebookId, cloudFileId];
}

// ── Conflict resolution ────────────────────────────────────────────────────

/// Resolve a sync conflict with the specified strategy.
class ResolveConflict extends CloudSyncEvent {
  const ResolveConflict({
    required this.notebookId,
    required this.resolution,
  });
  final String notebookId;
  final ConflictResolution resolution;
  @override
  List<Object?> get props => [notebookId, resolution];
}

/// Dismiss a conflict notification without resolving it.
class DismissConflict extends CloudSyncEvent {
  const DismissConflict({required this.notebookId});
  final String notebookId;
  @override
  List<Object?> get props => [notebookId];
}

// ── Settings ───────────────────────────────────────────────────────────────

/// Toggle automatic background sync on/off.
class ToggleAutoSync extends CloudSyncEvent {
  const ToggleAutoSync({required this.enabled});
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

/// Toggle Wi-Fi only sync restriction.
class ToggleWifiOnlySync extends CloudSyncEvent {
  const ToggleWifiOnlySync({required this.enabled});
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

/// Set the auto-sync interval in minutes.
class SetAutoSyncInterval extends CloudSyncEvent {
  const SetAutoSyncInterval({required this.minutes});
  final int minutes;
  @override
  List<Object?> get props => [minutes];
}

// ── Status ─────────────────────────────────────────────────────────────────

/// Clear any sync error status.
class ClearSyncError extends CloudSyncEvent {
  const ClearSyncError();
}

/// Refresh the list of remote notebooks.
class RefreshRemoteNotebooks extends CloudSyncEvent {
  const RefreshRemoteNotebooks();
}
