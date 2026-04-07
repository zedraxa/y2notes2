import 'package:equatable/equatable.dart';

/// Supported cloud storage providers.
enum CloudProviderType {
  iCloud,
  googleDrive,
  oneDrive,
  dropbox,
}

/// Configuration and authentication state for a cloud provider.
class CloudProviderConfig extends Equatable {
  const CloudProviderConfig({
    required this.type,
    this.isAuthenticated = false,
    this.accountEmail,
    this.accountName,
    this.rootFolderId,
    this.lastAuthenticatedAt,
    this.quotaUsedBytes = 0,
    this.quotaTotalBytes = 0,
  });

  /// The provider type.
  final CloudProviderType type;

  /// Whether the user has authenticated with this provider.
  final bool isAuthenticated;

  /// Email associated with the cloud account.
  final String? accountEmail;

  /// Display name of the cloud account owner.
  final String? accountName;

  /// Root folder ID where notebooks are stored in the cloud.
  final String? rootFolderId;

  /// When the user last authenticated.
  final DateTime? lastAuthenticatedAt;

  /// Storage quota used in bytes.
  final int quotaUsedBytes;

  /// Total storage quota in bytes.
  final int quotaTotalBytes;

  /// Human-readable display name for the provider.
  String get displayName {
    switch (type) {
      case CloudProviderType.iCloud:
        return 'iCloud';
      case CloudProviderType.googleDrive:
        return 'Google Drive';
      case CloudProviderType.oneDrive:
        return 'OneDrive';
      case CloudProviderType.dropbox:
        return 'Dropbox';
    }
  }

  /// Returns storage usage as a fraction [0.0, 1.0].
  double get quotaUsageFraction =>
      quotaTotalBytes > 0 ? quotaUsedBytes / quotaTotalBytes : 0.0;

  CloudProviderConfig copyWith({
    bool? isAuthenticated,
    String? accountEmail,
    String? accountName,
    String? rootFolderId,
    DateTime? lastAuthenticatedAt,
    int? quotaUsedBytes,
    int? quotaTotalBytes,
    bool clearAccount = false,
  }) =>
      CloudProviderConfig(
        type: type,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        accountEmail: clearAccount ? null : (accountEmail ?? this.accountEmail),
        accountName: clearAccount ? null : (accountName ?? this.accountName),
        rootFolderId: clearAccount ? null : (rootFolderId ?? this.rootFolderId),
        lastAuthenticatedAt: clearAccount
            ? null
            : (lastAuthenticatedAt ?? this.lastAuthenticatedAt),
        quotaUsedBytes: clearAccount
            ? 0
            : (quotaUsedBytes ?? this.quotaUsedBytes),
        quotaTotalBytes: clearAccount
            ? 0
            : (quotaTotalBytes ?? this.quotaTotalBytes),
      );

  @override
  List<Object?> get props => [
        type,
        isAuthenticated,
        accountEmail,
        accountName,
        rootFolderId,
        lastAuthenticatedAt,
        quotaUsedBytes,
        quotaTotalBytes,
      ];
}
