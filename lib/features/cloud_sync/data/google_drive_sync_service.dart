import 'package:biscuits/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/sync_metadata.dart';

/// Google Drive implementation of [CloudSyncService].
///
/// This is a stub that outlines the Google Drive integration API surface.
/// A full implementation would use the Google Sign-In and Google Drive API
/// via packages such as `google_sign_in` and `googleapis`.
class GoogleDriveSyncService implements CloudSyncService {
  @override
  CloudProviderType get providerType => CloudProviderType.googleDrive;

  @override
  Future<CloudProviderConfig> authenticate() async {
    // Stub: In production, this would trigger Google Sign-In flow
    // and request Drive API scopes.
    return CloudProviderConfig(
      type: providerType,
      isAuthenticated: true,
      accountName: 'Google User',
      accountEmail: 'user@gmail.com',
      lastAuthenticatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    // Stub: Would call GoogleSignIn.signOut().
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
    // Stub: Would use Drive API files.create or files.update.
    onProgress?.call(data.length, data.length);
    return SyncMetadata(
      notebookId: notebookId,
      provider: providerType,
      cloudFileId: existingCloudFileId ?? 'gdrive_${notebookId}',
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
    // Stub: Would use Drive API files.get with alt=media.
    onProgress?.call(0, 0);
    return [];
  }

  @override
  Future<List<SyncMetadata>> listRemoteNotebooks() async => [];

  @override
  Future<void> deleteRemoteNotebook({required String cloudFileId}) async {}

  @override
  Future<({int usedBytes, int totalBytes})> getStorageQuota() async =>
      (usedBytes: 0, totalBytes: 15 * 1024 * 1024 * 1024); // 15 GB stub

  @override
  Future<bool> hasRemoteChanges({
    required String cloudFileId,
    required DateTime since,
  }) async =>
      false;
}
