import 'package:equatable/equatable.dart';

/// Represents a single browser-like tab in the workspace.
class TabSession extends Equatable {
  const TabSession({
    required this.id,
    required this.title,
    this.isPinned = false,
    this.isModified = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isPinned;

  /// Whether this tab has unsaved changes.
  final bool isModified;
  final DateTime createdAt;

  TabSession copyWith({
    String? title,
    bool? isPinned,
    bool? isModified,
  }) =>
      TabSession(
        id: id,
        title: title ?? this.title,
        isPinned: isPinned ?? this.isPinned,
        isModified: isModified ?? this.isModified,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, isPinned, isModified, createdAt];
}
