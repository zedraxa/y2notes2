import 'package:y2notes2/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/sync_metadata.dart';

/// Dropbox implementation of [CloudSyncService].
///
/// This is a stub that outlines the Dropbox integration API surface.
/// A full implementation would use the Dropbox API v2 with OAuth 2.0
/// authentication.
class DropboxSyncService implements CloudSyncService {
  @override
  CloudProviderType get providerType => CloudProviderType.dropbox;

  @override
  Future<CloudProviderConfig> authenticate() async {
    // Stub: In production, this would trigger Dropbox OAuth2 flow.
    return CloudProviderConfig(
      type: providerType,
      isAuthenticated: true,
      accountName: 'Dropbox User',
      accountEmail: 'user@dropbox.com',
      lastAuthenticatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    // Stub: Would revoke the Dropbox access token.
  }

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<SyncMetadata> uploadNotebook({
    required String notebookId,
    required List<int> data,
    required String fileName,
    String? existingCloudFileId,
    void Function(int bytesTransferred, int totalBytes)? onProgress,
  }) async {
    // Stub: Would use Dropbox files/upload endpoint.
    onProgress?.call(data.length, data.length);
    return SyncMetadata(
      notebookId: notebookId,
      provider: providerType,
      cloudFileId: existingCloudFileId ?? 'dropbox_${notebookId}',
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncOperationStatus.success,
      lastDirection: SyncDirection.upload,
    );
  }

  @override
  Future<List<int>> downloadNotebook({
    required String cloudFileId,
    void Function(int bytesTransferred, int totalBytes)? onProgress,
  }) async {
    // Stub: Would use Dropbox files/download endpoint.
    onProgress?.call(0, 0);
    return [];
  }

  @override
  Future<List<SyncMetadata>> listRemoteNotebooks() async => [];

  @override
  Future<void> deleteRemoteNotebook({required String cloudFileId}) async {}

  @override
  Future<({int usedBytes, int totalBytes})> getStorageQuota() async =>
      (usedBytes: 0, totalBytes: 2 * 1024 * 1024 * 1024); // 2 GB stub

  @override
  Future<bool> hasRemoteChanges({
    required String cloudFileId,
    required DateTime since,
  }) async =>
      false;
}
