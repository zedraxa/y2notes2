import 'package:biscuits/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/sync_metadata.dart';

/// OneDrive implementation of [CloudSyncService].
///
/// This is a stub that outlines the OneDrive integration API surface.
/// A full implementation would use the Microsoft Graph API via MSAL
/// authentication (e.g. `msal_flutter` or `aad_oauth` packages).
class OneDriveSyncService implements CloudSyncService {
  @override
  CloudProviderType get providerType => CloudProviderType.oneDrive;

  @override
  Future<CloudProviderConfig> authenticate() async {
    // Stub: In production, this would trigger MSAL authentication
    // and request Files.ReadWrite scope.
    return CloudProviderConfig(
      type: providerType,
      isAuthenticated: true,
      accountName: 'OneDrive User',
      accountEmail: 'user@outlook.com',
      lastAuthenticatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    // Stub: Would clear MSAL token cache.
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
    // Stub: Would use Graph API PUT /me/drive/items/{id}/content.
    onProgress?.call(data.length, data.length);
    return SyncMetadata(
      notebookId: notebookId,
      provider: providerType,
      cloudFileId: existingCloudFileId ?? 'onedrive_${notebookId}',
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
    // Stub: Would use Graph API GET /me/drive/items/{id}/content.
    onProgress?.call(0, 0);
    return [];
  }

  @override
  Future<List<SyncMetadata>> listRemoteNotebooks() async => [];

  @override
  Future<void> deleteRemoteNotebook({required String cloudFileId}) async {}

  @override
  Future<({int usedBytes, int totalBytes})> getStorageQuota() async =>
      (usedBytes: 0, totalBytes: 5 * 1024 * 1024 * 1024); // 5 GB stub

  @override
  Future<bool> hasRemoteChanges({
    required String cloudFileId,
    required DateTime since,
  }) async =>
      false;
}
