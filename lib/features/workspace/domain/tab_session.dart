import 'package:equatable/equatable.dart';

/// Represents a single browser-like tab in the workspace.
class TabSession extends Equatable {
  const TabSession({
    required this.id,
    required this.title,
    this.isPinned = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isPinned;
  final DateTime createdAt;

  TabSession copyWith({
    String? title,
    bool? isPinned,
  }) =>
      TabSession(
        id: id,
        title: title ?? this.title,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, isPinned, createdAt];
}
