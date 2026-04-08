import 'package:equatable/equatable.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/sync_conflict.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/sync_metadata.dart';

/// Immutable snapshot of the cloud sync feature state.
class CloudSyncState extends Equatable {
  const CloudSyncState({
    this.providers = const {},
    this.activeProvider,
    this.syncMetadata = const {},
    this.conflicts = const [],
    this.isAutoSyncEnabled = false,
    this.isWifiOnlyEnabled = true,
    this.autoSyncIntervalMinutes = 15,
    this.isSyncing = false,
    this.syncProgress = 0.0,
    this.errorMessage,
    this.lastGlobalSyncAt,
    this.remoteNotebooks = const [],
    this.isLoadingRemote = false,
  });

  /// Configuration for each connected cloud provider.
  final Map<CloudProviderType, CloudProviderConfig> providers;

  /// The currently active cloud provider used for syncing.
  final CloudProviderType? activeProvider;

  /// Sync metadata keyed by notebook ID.
  final Map<String, SyncMetadata> syncMetadata;

  /// Active unresolved conflicts.
  final List<SyncConflict> conflicts;

  /// Whether automatic background sync is enabled.
  final bool isAutoSyncEnabled;

  /// Whether sync should only occur over Wi-Fi.
  final bool isWifiOnlyEnabled;

  /// How often to auto-sync in minutes.
  final int autoSyncIntervalMinutes;

  /// Whether a sync operation is currently in progress.
  final bool isSyncing;

  /// Progress of the current sync operation [0.0, 1.0].
  final double syncProgress;

  /// Error message from the last failed operation.
  final String? errorMessage;

  /// When any notebook was last synced globally.
  final DateTime? lastGlobalSyncAt;

  /// Remote notebooks discovered in the cloud.
  final List<SyncMetadata> remoteNotebooks;

  /// Whether we're loading the list of remote notebooks.
  final bool isLoadingRemote;

  // ── Derived getters ──────────────────────────────────────────────────────

  /// Whether a provider is connected and active.
  bool get hasActiveProvider =>
      activeProvider != null &&
      (providers[activeProvider]?.isAuthenticated ?? false);

  /// The active provider config, if any.
  CloudProviderConfig? get activeProviderConfig =>
      activeProvider != null ? providers[activeProvider] : null;

  /// Number of notebooks with pending local changes.
  int get pendingChangesCount =>
      syncMetadata.values.where((m) => m.hasPendingChanges).length;

  /// Whether there are unresolved conflicts.
  bool get hasConflicts => conflicts.where((c) => !c.isResolved).isNotEmpty;

  /// Whether there's an error.
  bool get hasError => errorMessage != null;

  /// Connected provider count.
  int get connectedProviderCount =>
      providers.values.where((p) => p.isAuthenticated).length;

  CloudSyncState copyWith({
    Map<CloudProviderType, CloudProviderConfig>? providers,
    CloudProviderType? activeProvider,
    bool clearActiveProvider = false,
    Map<String, SyncMetadata>? syncMetadata,
    List<SyncConflict>? conflicts,
    bool? isAutoSyncEnabled,
    bool? isWifiOnlyEnabled,
    int? autoSyncIntervalMinutes,
    bool? isSyncing,
    double? syncProgress,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastGlobalSyncAt,
    List<SyncMetadata>? remoteNotebooks,
    bool? isLoadingRemote,
  }) =>
      CloudSyncState(
        providers: providers ?? this.providers,
        activeProvider: clearActiveProvider
            ? null
            : (activeProvider ?? this.activeProvider),
        syncMetadata: syncMetadata ?? this.syncMetadata,
        conflicts: conflicts ?? this.conflicts,
        isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
        isWifiOnlyEnabled: isWifiOnlyEnabled ?? this.isWifiOnlyEnabled,
        autoSyncIntervalMinutes:
            autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
        isSyncing: isSyncing ?? this.isSyncing,
        syncProgress: syncProgress ?? this.syncProgress,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        lastGlobalSyncAt: lastGlobalSyncAt ?? this.lastGlobalSyncAt,
        remoteNotebooks: remoteNotebooks ?? this.remoteNotebooks,
        isLoadingRemote: isLoadingRemote ?? this.isLoadingRemote,
      );

  @override
  List<Object?> get props => [
        providers,
        activeProvider,
        syncMetadata,
        conflicts,
        isAutoSyncEnabled,
        isWifiOnlyEnabled,
        autoSyncIntervalMinutes,
        isSyncing,
        syncProgress,
        errorMessage,
        lastGlobalSyncAt,
        remoteNotebooks,
        isLoadingRemote,
      ];
}
