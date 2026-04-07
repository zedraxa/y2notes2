import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// A folder that can contain notebooks, canvases, or other folders.
class Folder extends Equatable {
  Folder({
    String? id,
    required this.name,
    this.parentFolderId,
    this.color,
    this.emoji,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.childCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;

  /// `null` means this folder lives at the root level.
  final String? parentFolderId;

  final Color? color;
  final String? emoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed count of immediate children (items + sub-folders).
  final int childCount;

  bool get isRoot => parentFolderId == null;

  Folder copyWith({
    String? name,
    String? parentFolderId,
    Color? color,
    String? emoji,
    DateTime? updatedAt,
    int? childCount,
  }) =>
      Folder(
        id: id,
        name: name ?? this.name,
        parentFolderId: parentFolderId ?? this.parentFolderId,
        color: color ?? this.color,
        emoji: emoji ?? this.emoji,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        childCount: childCount ?? this.childCount,
      );

  @override
  List<Object?> get props =>
      [id, name, parentFolderId, color, emoji, createdAt, childCount];
}
