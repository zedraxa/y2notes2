/// Permission levels for collaboration sessions.
enum PermissionLevel {
  /// Full control: can edit, invite, remove participants, and close the session.
  owner,

  /// Can draw, place stickers, and modify canvas content.
  editor,

  /// Read-only access — cannot modify canvas content.
  viewer,
}

extension PermissionLevelX on PermissionLevel {
  bool get canEdit =>
      this == PermissionLevel.owner || this == PermissionLevel.editor;

  bool get canManageSession => this == PermissionLevel.owner;

  String get label {
    switch (this) {
      case PermissionLevel.owner:
        return 'Owner';
      case PermissionLevel.editor:
        return 'Editor';
      case PermissionLevel.viewer:
        return 'Viewer';
    }
  }
}
