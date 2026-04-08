import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:y2notes2/features/cloud_sync/data/dropbox_sync_service.dart';
import 'package:y2notes2/features/cloud_sync/data/google_drive_sync_service.dart';
import 'package:y2notes2/features/cloud_sync/data/icloud_sync_service.dart';
import 'package:y2notes2/features/cloud_sync/data/onedrive_sync_service.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/sync_metadata.dart';
import 'package:y2notes2/features/cloud_sync/engine/conflict_resolution_engine.dart';
import 'package:y2notes2/features/cloud_sync/presentation/bloc/cloud_sync_event.dart';
import 'package:y2notes2/features/cloud_sync/presentation/bloc/cloud_sync_state.dart';

/// BLoC that manages cloud synchronization state, provider connections,
/// sync operations, and conflict resolution.
class CloudSyncBloc extends Bloc<CloudSyncEvent, CloudSyncState> {
  CloudSyncBloc({
    ConflictResolutionEngine? conflictEngine,
  })  : _conflictEngine = conflictEngine ?? const ConflictResolutionEngine(),
        super(const CloudSyncState()) {
    // Register provider services.
    _services = {
      CloudProviderType.iCloud: ICloudSyncService(),
      CloudProviderType.googleDrive: GoogleDriveSyncService(),
      CloudProviderType.oneDrive: OneDriveSyncService(),
      CloudProviderType.dropbox: DropboxSyncService(),
    };

    on<ConnectProvider>(_onConnectProvider);
    on<DisconnectProvider>(_onDisconnectProvider);
    on<SetActiveProvider>(_onSetActiveProvider);
    on<SyncNow>(_onSyncNow);
    on<SyncAllNotebooks>(_onSyncAllNotebooks);
    on<UploadNotebook>(_onUploadNotebook);
    on<DownloadNotebook>(_onDownloadNotebook);
    on<ResolveConflict>(_onResolveConflict);
    on<DismissConflict>(_onDismissConflict);
    on<ToggleAutoSync>(_onToggleAutoSync);
    on<ToggleWifiOnlySync>(_onToggleWifiOnlySync);
    on<SetAutoSyncInterval>(_onSetAutoSyncInterval);
    on<ClearSyncError>(_onClearSyncError);
    on<RefreshRemoteNotebooks>(_onRefreshRemoteNotebooks);
  }

  late final Map<CloudProviderType, CloudSyncService> _services;
  final ConflictResolutionEngine _conflictEngine;

  // ── Provider management ──────────────────────────────────────────────────

  Future<void> _onConnectProvider(
    ConnectProvider event,
    Emitter<CloudSyncState> emit,
  ) async {
    final service = _services[event.providerType];
    if (service == null) return;

    try {
      emit(state.copyWith(isSyncing: true));

      final config = await service.authenticate();
      final quota = await service.getStorageQuota();

      final updatedConfig = config.copyWith(
        quotaUsedBytes: quota.usedBytes,
        quotaTotalBytes: quota.totalBytes,
      );

      final providers = Map<CloudProviderType, CloudProviderConfig>.from(
        state.providers,
      )..[event.providerType] = updatedConfig;

      emit(state.copyWith(
        providers: providers,
        activeProvider: event.providerType,
        isSyncing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to connect to '
            '${event.providerType.name}: $e',
      ));
    }
  }

  Future<void> _onDisconnectProvider(
    DisconnectProvider event,
    Emitter<CloudSyncState> emit,
  ) async {
    final service = _services[event.providerType];
    if (service == null) return;

    try {
      await service.signOut();

      final providers = Map<CloudProviderType, CloudProviderConfig>.from(
        state.providers,
      )..remove(event.providerType);

      final clearActive = state.activeProvider == event.providerType;

      emit(state.copyWith(
        providers: providers,
        clearActiveProvider: clearActive,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to disconnect: $e',
      ));
    }
  }

  void _onSetActiveProvider(
    SetActiveProvider event,
    Emitter<CloudSyncState> emit,
  ) {
    final config = state.providers[event.providerType];
    if (config == null || !config.isAuthenticated) return;
    emit(state.copyWith(activeProvider: event.providerType));
  }

  // ── Sync operations ──────────────────────────────────────────────────────

  Future<void> _onSyncNow(
    SyncNow event,
    Emitter<CloudSyncState> emit,
  ) async {
    if (!state.hasActiveProvider) {
      emit(state.copyWith(
        errorMessage: 'No cloud provider connected.',
      ));
      return;
    }

    final service = _services[state.activeProvider!]!;
    final metadata = state.syncMetadata[event.notebookId];

    emit(state.copyWith(isSyncing: true, syncProgress: 0.0));

    try {
      // Check for conflicts.
      if (metadata != null && _conflictEngine.detectConflict(metadata)) {
        final conflict = _conflictEngine.createConflict(
          metadata: metadata,
          notebookTitle: 'Notebook', // Caller should provide actual title.
        );
        emit(state.copyWith(
          isSyncing: false,
          conflicts: [...state.conflicts, conflict],
        ));
        return;
      }

      // Check for remote changes first.
      if (metadata?.cloudFileId != null && metadata?.lastSyncedAt != null) {
        final hasRemote = await service.hasRemoteChanges(
          cloudFileId: metadata!.cloudFileId!,
          since: metadata.lastSyncedAt!,
        );

        if (hasRemote) {
          // Download remote changes.
          await service.downloadNotebook(
            cloudFileId: metadata.cloudFileId!,
            onProgress: (transferred, total) {
              emit(state.copyWith(
                syncProgress: total > 0 ? transferred / total : 0.5,
              ));
            },
          );
        }
      }

      // Upload local changes.
      // Note: In a real implementation, we'd serialize the notebook data here.
      final updatedMetadata = await service.uploadNotebook(
        notebookId: event.notebookId,
        data: [], // Stub: Would be serialized notebook JSON bytes.
        fileName: '${event.notebookId}.y2nb',
        existingCloudFileId: metadata?.cloudFileId,
        onProgress: (transferred, total) {
          emit(state.copyWith(
            syncProgress: total > 0 ? transferred / total : 0.5,
          ));
        },
      );

      final syncMap = Map<String, SyncMetadata>.from(state.syncMetadata)
        ..[event.notebookId] = updatedMetadata;

      emit(state.copyWith(
        isSyncing: false,
        syncProgress: 1.0,
        syncMetadata: syncMap,
        lastGlobalSyncAt: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: 'Sync failed: $e',
      ));
    }
  }

  Future<void> _onSyncAllNotebooks(
    SyncAllNotebooks event,
    Emitter<CloudSyncState> emit,
  ) async {
    if (!state.hasActiveProvider) return;

    emit(state.copyWith(isSyncing: true, syncProgress: 0.0));

    final pending = state.syncMetadata.entries
        .where((e) => e.value.hasPendingChanges)
        .toList();

    if (pending.isEmpty) {
      emit(state.copyWith(
        isSyncing: false,
        syncProgress: 1.0,
        lastGlobalSyncAt: DateTime.now(),
      ));
      return;
    }

    for (var i = 0; i < pending.length; i++) {
      add(SyncNow(notebookId: pending[i].key));
      emit(state.copyWith(
        syncProgress: (i + 1) / pending.length,
      ));
    }
  }

  Future<void> _onUploadNotebook(
    UploadNotebook event,
    Emitter<CloudSyncState> emit,
  ) async {
    if (!state.hasActiveProvider) return;

    final service = _services[state.activeProvider!]!;

    emit(state.copyWith(isSyncing: true, syncProgress: 0.0));

    try {
      final metadata = await service.uploadNotebook(
        notebookId: event.notebookId,
        data: [], // Stub: Would be serialized notebook data.
        fileName: '${event.notebookId}.y2nb',
        onProgress: (transferred, total) {
          emit(state.copyWith(
            syncProgress: total > 0 ? transferred / total : 0.5,
          ));
        },
      );

      final syncMap = Map<String, SyncMetadata>.from(state.syncMetadata)
        ..[event.notebookId] = metadata;

      emit(state.copyWith(
        isSyncing: false,
        syncProgress: 1.0,
        syncMetadata: syncMap,
        lastGlobalSyncAt: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: 'Upload failed: $e',
      ));
    }
  }

  Future<void> _onDownloadNotebook(
    DownloadNotebook event,
    Emitter<CloudSyncState> emit,
  ) async {
    if (!state.hasActiveProvider) return;

    final service = _services[state.activeProvider!]!;

    emit(state.copyWith(isSyncing: true, syncProgress: 0.0));

    try {
      await service.downloadNotebook(
        cloudFileId: event.cloudFileId,
        onProgress: (transferred, total) {
          emit(state.copyWith(
            syncProgress: total > 0 ? transferred / total : 0.5,
          ));
        },
      );

      // Stub: Would deserialize and store the notebook locally.

      final metadata = SyncMetadata(
        notebookId: event.notebookId,
        provider: state.activeProvider!,
        cloudFileId: event.cloudFileId,
        lastSyncedAt: DateTime.now(),
        syncStatus: SyncOperationStatus.success,
        lastDirection: SyncDirection.download,
      );

      final syncMap = Map<String, SyncMetadata>.from(state.syncMetadata)
        ..[event.notebookId] = metadata;

      emit(state.copyWith(
        isSyncing: false,
        syncProgress: 1.0,
        syncMetadata: syncMap,
        lastGlobalSyncAt: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: 'Download failed: $e',
      ));
    }
  }

  // ── Conflict resolution ──────────────────────────────────────────────────

  void _onResolveConflict(
    ResolveConflict event,
    Emitter<CloudSyncState> emit,
  ) {
    final updated = state.conflicts.map((c) {
      if (c.notebookId == event.notebookId) {
        return c.copyWith(
          resolution: event.resolution,
          isResolved: true,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(conflicts: updated));

    // Trigger sync in the resolved direction.
    final direction = _conflictEngine.applyResolution(event.resolution);
    if (direction == SyncDirection.upload ||
        direction == SyncDirection.bidirectional) {
      add(SyncNow(notebookId: event.notebookId));
    }
  }

  void _onDismissConflict(
    DismissConflict event,
    Emitter<CloudSyncState> emit,
  ) {
    final updated = state.conflicts
        .where((c) => c.notebookId != event.notebookId)
        .toList();
    emit(state.copyWith(conflicts: updated));
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  void _onToggleAutoSync(
    ToggleAutoSync event,
    Emitter<CloudSyncState> emit,
  ) =>
      emit(state.copyWith(isAutoSyncEnabled: event.enabled));

  void _onToggleWifiOnlySync(
    ToggleWifiOnlySync event,
    Emitter<CloudSyncState> emit,
  ) =>
      emit(state.copyWith(isWifiOnlyEnabled: event.enabled));

  void _onSetAutoSyncInterval(
    SetAutoSyncInterval event,
    Emitter<CloudSyncState> emit,
  ) =>
      emit(state.copyWith(
        autoSyncIntervalMinutes: event.minutes.clamp(1, 60),
      ));

  void _onClearSyncError(
    ClearSyncError event,
    Emitter<CloudSyncState> emit,
  ) =>
      emit(state.copyWith(clearError: true));

  Future<void> _onRefreshRemoteNotebooks(
    RefreshRemoteNotebooks event,
    Emitter<CloudSyncState> emit,
  ) async {
    if (!state.hasActiveProvider) return;

    final service = _services[state.activeProvider!]!;

    emit(state.copyWith(isLoadingRemote: true));

    try {
      final remoteList = await service.listRemoteNotebooks();
      emit(state.copyWith(
        remoteNotebooks: remoteList,
        isLoadingRemote: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingRemote: false,
        errorMessage: 'Failed to list remote notebooks: $e',
      ));
    }
  }
}
