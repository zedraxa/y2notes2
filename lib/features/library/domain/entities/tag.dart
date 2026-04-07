import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// A user-defined tag that can be applied to library items.
///
/// Tags support up to three levels of hierarchy, e.g. School → Math → Calculus.
class Tag extends Equatable {
  Tag({
    String? id,
    required this.name,
    required this.color,
    this.parentTagId,
    this.emoji,
    this.usageCount = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final Color color;

  /// Parent tag id for hierarchical tags; `null` means top-level.
  final String? parentTagId;
  final String? emoji;

  /// How many library items currently use this tag.
  final int usageCount;
  final DateTime createdAt;

  bool get isTopLevel => parentTagId == null;

  Tag copyWith({
    String? name,
    Color? color,
    Object? parentTagId = _sentinel,
    Object? emoji = _sentinel,
    int? usageCount,
  }) =>
      Tag(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        parentTagId:
            parentTagId == _sentinel ? this.parentTagId : parentTagId as String?,
        emoji: emoji == _sentinel ? this.emoji : emoji as String?,
        usageCount: usageCount ?? this.usageCount,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, name, color, parentTagId, emoji, usageCount, createdAt];
}

const _sentinel = Object();
