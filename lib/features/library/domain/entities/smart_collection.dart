import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuitse/features/library/domain/entities/library_item.dart';

/// The rule that determines which items appear in a smart collection.
enum SmartCollectionRule {
  /// Items modified in the last 7 days.
  recent,

  /// Items marked as favourite.
  favorites,

  /// Items that have at least one active collaboration session.
  shared,

  /// Notebooks with 10 or more pages.
  largeNotebooks,

  /// User-defined combination of tag/date/type rules.
  custom,
}

/// A virtual collection that is auto-populated based on [SmartCollectionRule].
class SmartCollection extends Equatable {
  SmartCollection({
    String? id,
    required this.name,
    required this.rule,
    this.emoji,
    Set<String>? requiredTagIds,
    Set<LibraryItemType>? requiredTypes,
    this.minPageCount,
    this.withinDays,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        requiredTagIds = requiredTagIds ?? const {},
        requiredTypes = requiredTypes ?? const {},
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final SmartCollectionRule rule;
  final String? emoji;

  // Custom rule parameters
  final Set<String> requiredTagIds;
  final Set<LibraryItemType> requiredTypes;

  /// For [SmartCollectionRule.largeNotebooks] / custom: minimum page count.
  final int? minPageCount;

  /// For [SmartCollectionRule.recent] / custom: items modified within N days.
  final int? withinDays;

  final DateTime createdAt;

  /// Evaluate whether [item] matches this collection's rule.
  ///
  /// [pageCount] is only relevant for [SmartCollectionRule.largeNotebooks].
  bool matches(LibraryItem item, {int pageCount = 0}) {
    if (item.isInTrash) return false;
    switch (rule) {
      case SmartCollectionRule.recent:
        final days = withinDays ?? 7;
        return DateTime.now().difference(item.updatedAt).inDays <= days;
      case SmartCollectionRule.favorites:
        return item.isFavorite;
      case SmartCollectionRule.shared:
        // Shared state is managed externally; include all non-trash items for now.
        return false;
      case SmartCollectionRule.largeNotebooks:
        final min = minPageCount ?? 10;
        return item.type == LibraryItemType.notebook && pageCount >= min;
      case SmartCollectionRule.custom:
        final typeOk = requiredTypes.isEmpty ||
            requiredTypes.contains(item.type);
        final tagsOk = requiredTagIds.isEmpty ||
            item.tagIds.any(requiredTagIds.contains);
        return typeOk && tagsOk;
    }
  }

  SmartCollection copyWith({
    String? name,
    SmartCollectionRule? rule,
    Object? emoji = _sentinel,
    Set<String>? requiredTagIds,
    Set<LibraryItemType>? requiredTypes,
    Object? minPageCount = _sentinel,
    Object? withinDays = _sentinel,
  }) =>
      SmartCollection(
        id: id,
        name: name ?? this.name,
        rule: rule ?? this.rule,
        emoji: emoji == _sentinel ? this.emoji : emoji as String?,
        requiredTagIds: requiredTagIds ?? this.requiredTagIds,
        requiredTypes: requiredTypes ?? this.requiredTypes,
        minPageCount: minPageCount == _sentinel
            ? this.minPageCount
            : minPageCount as int?,
        withinDays:
            withinDays == _sentinel ? this.withinDays : withinDays as int?,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        rule,
        emoji,
        requiredTagIds,
        requiredTypes,
        minPageCount,
        withinDays,
        createdAt,
      ];
}

const _sentinel = Object();

/// Built-in smart collections shown by default.
List<SmartCollection> defaultSmartCollections() => [
      SmartCollection(
        name: 'Recent',
        rule: SmartCollectionRule.recent,
        emoji: '🕐',
        withinDays: 7,
      ),
      SmartCollection(
        name: 'Favorites',
        rule: SmartCollectionRule.favorites,
        emoji: '⭐',
      ),
      SmartCollection(
        name: 'Large Notebooks',
        rule: SmartCollectionRule.largeNotebooks,
        emoji: '📚',
        minPageCount: 10,
      ),
    ];
