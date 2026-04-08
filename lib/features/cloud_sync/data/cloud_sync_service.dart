import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/sync_metadata.dart';

/// Abstract interface for cloud storage provider implementations.
///
/// Each provider (iCloud, Google Drive, OneDrive, Dropbox) must implement
/// this interface. In a production app, each implementation would integrate
/// with the respective cloud SDK. Currently, all implementations are stubs
/// that outline the expected API surface.
abstract class CloudSyncService {
  /// The provider type this service handles.
  CloudProviderType get providerType;

  /// Authenticate the user with the cloud provider.
  ///
  /// Returns an updated [CloudProviderConfig] with authentication state.
  Future<CloudProviderConfig> authenticate();

  /// Sign out and revoke access tokens.
  Future<void> signOut();

  /// Check whether the user is currently authenticated.
  Future<bool> isAuthenticated();

  /// Upload a serialised notebook (JSON bytes) to the cloud.
  ///
  /// Returns updated [SyncMetadata] with the new cloud file ID and version.
  Future<SyncMetadata> uploadNotebook({
    required String notebookId,
    required List<int> data,
    required String fileName,
    String? existingCloudFileId,
    void Function(int bytesTransferred, int totalBytes)? onProgress,
  });

  /// Download a notebook from the cloud by its cloud file ID.
  ///
  /// Returns the raw JSON bytes.
  Future<List<int>> downloadNotebook({
    required String cloudFileId,
    void Function(int bytesTransferred, int totalBytes)? onProgress,
  });

  /// List all notebooks stored in the cloud root folder.
  ///
  /// Returns a list of [SyncMetadata] entries for each remote notebook.
  Future<List<SyncMetadata>> listRemoteNotebooks();

  /// Delete a notebook from the cloud.
  Future<void> deleteRemoteNotebook({required String cloudFileId});

  /// Fetch the storage quota information.
  Future<({int usedBytes, int totalBytes})> getStorageQuota();

  /// Check if the remote notebook has been modified since [since].
  Future<bool> hasRemoteChanges({
    required String cloudFileId,
    required DateTime since,
  });
}
