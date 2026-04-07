import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// The type of a library item.
enum LibraryItemType { notebook, infiniteCanvas, folder }

/// Color label options for library items.
enum ColorLabel { red, orange, yellow, green, blue, purple }

extension ColorLabelX on ColorLabel {
  Color get color {
    switch (this) {
      case ColorLabel.red:
        return const Color(0xFFFF3B30);
      case ColorLabel.orange:
        return const Color(0xFFFF9500);
      case ColorLabel.yellow:
        return const Color(0xFFFFCC00);
      case ColorLabel.green:
        return const Color(0xFF34C759);
      case ColorLabel.blue:
        return const Color(0xFF007AFF);
      case ColorLabel.purple:
        return const Color(0xFFAF52DE);
    }
  }

  String get label {
    switch (this) {
      case ColorLabel.red:
        return 'Red';
      case ColorLabel.orange:
        return 'Orange';
      case ColorLabel.yellow:
        return 'Yellow';
      case ColorLabel.green:
        return 'Green';
      case ColorLabel.blue:
        return 'Blue';
      case ColorLabel.purple:
        return 'Purple';
    }
  }
}

/// A single item in the library — notebook, infinite canvas, or folder link.
class LibraryItem extends Equatable {
  LibraryItem({
    String? id,
    required this.type,
    required this.name,
    this.folderId,
    this.thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tagIds,
    this.colorLabel,
    this.isFavorite = false,
    this.isInTrash = false,
    this.trashedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tagIds = tagIds ?? const [];

  final String id;
  final LibraryItemType type;
  final String name;

  /// The folder this item belongs to; `null` = root level.
  final String? folderId;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tagIds;
  final ColorLabel? colorLabel;
  final bool isFavorite;
  final bool isInTrash;

  /// Set when the item is moved to trash; used for auto-purge after 30 days.
  final DateTime? trashedAt;

  bool get isDueForAutoPurge {
    if (trashedAt == null) return false;
    return DateTime.now().difference(trashedAt!).inDays >= 30;
  }

  LibraryItem copyWith({
    LibraryItemType? type,
    String? name,
    Object? folderId = _sentinel,
    Object? thumbnailPath = _sentinel,
    DateTime? updatedAt,
    List<String>? tagIds,
    Object? colorLabel = _sentinel,
    bool? isFavorite,
    bool? isInTrash,
    Object? trashedAt = _sentinel,
  }) =>
      LibraryItem(
        id: id,
        type: type ?? this.type,
        name: name ?? this.name,
        folderId: folderId == _sentinel ? this.folderId : folderId as String?,
        thumbnailPath: thumbnailPath == _sentinel
            ? this.thumbnailPath
            : thumbnailPath as String?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        tagIds: tagIds ?? this.tagIds,
        colorLabel:
            colorLabel == _sentinel ? this.colorLabel : colorLabel as ColorLabel?,
        isFavorite: isFavorite ?? this.isFavorite,
        isInTrash: isInTrash ?? this.isInTrash,
        trashedAt:
            trashedAt == _sentinel ? this.trashedAt : trashedAt as DateTime?,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        folderId,
        thumbnailPath,
        createdAt,
        updatedAt,
        tagIds,
        colorLabel,
        isFavorite,
        isInTrash,
        trashedAt,
      ];
}

const _sentinel = Object();
