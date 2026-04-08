import 'package:equatable/equatable.dart';
import 'package:biscuits/features/library/domain/entities/folder.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/search_result.dart';
import 'package:biscuits/features/library/domain/entities/smart_collection.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';

/// Immutable snapshot of the library UI state.
class LibraryState extends Equatable {
  const LibraryState({
    this.items = const [],
    this.trashItems = const [],
    this.folders = const [],
    this.tags = const [],
    this.smartCollections = const [],
    this.currentFolderId,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearchMode = false,
    this.viewMode = LibraryViewMode.grid,
    this.sortOrder = LibrarySortOrder.dateModified,
    this.filterTagIds = const {},
    this.filterTypes = const {},
    this.filterColorLabel,
    this.filterIsFavorite,
    this.activeSmartCollection,
    this.isSpotlightOpen = false,
    this.isLoading = false,
    this.error,
  });

  /// All non-trashed library items.
  final List<LibraryItem> items;

  /// Items currently in the trash.
  final List<LibraryItem> trashItems;
  final List<Folder> folders;
  final List<Tag> tags;
  final List<SmartCollection> smartCollections;

  /// Currently browsed folder; `null` = root.
  final String? currentFolderId;

  // ── Search ──────────────────────────────────────────────────────────────
  final String searchQuery;
  final List<SearchResult> searchResults;
  final bool isSearchMode;
  final bool isSpotlightOpen;

  // ── View options ─────────────────────────────────────────────────────────
  final LibraryViewMode viewMode;
  final LibrarySortOrder sortOrder;

  // ── Active filters ────────────────────────────────────────────────────────
  final Set<String> filterTagIds;
  final Set<LibraryItemType> filterTypes;
  final ColorLabel? filterColorLabel;
  final bool? filterIsFavorite;

  /// Active smart collection filter; `null` = no smart collection selected.
  final SmartCollection? activeSmartCollection;

  // ── Async state ───────────────────────────────────────────────────────────
  final bool isLoading;
  final String? error;

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isSearching => isSearchMode;

  bool get hasActiveFilters =>
      filterTagIds.isNotEmpty ||
      filterTypes.isNotEmpty ||
      filterColorLabel != null ||
      filterIsFavorite != null ||
      activeSmartCollection != null;

  /// Items that pass active filters, sorted.
  ///
  /// When an [activeSmartCollection] is active the folder constraint is lifted
  /// so that the collection spans the entire library.
  List<LibraryItem> get visibleItems {
    var result = items.where((item) {
      if (item.isInTrash) return false;
      // Smart collections are library-wide; skip the folder constraint.
      if (activeSmartCollection == null && item.folderId != currentFolderId) {
        return false;
      }
      if (filterTagIds.isNotEmpty &&
          !item.tagIds.any(filterTagIds.contains)) return false;
      if (filterTypes.isNotEmpty && !filterTypes.contains(item.type)) {
        return false;
      }
      if (filterColorLabel != null && item.colorLabel != filterColorLabel) {
        return false;
      }
      if (filterIsFavorite != null && item.isFavorite != filterIsFavorite) {
        return false;
      }
      if (activeSmartCollection != null &&
          !activeSmartCollection!.matches(item)) {
        return false;
      }
      return true;
    }).toList();

    switch (sortOrder) {
      case LibrarySortOrder.dateModified:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case LibrarySortOrder.dateCreated:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LibrarySortOrder.name:
        result.sort((a, b) => a.name.compareTo(b.name));
      case LibrarySortOrder.size:
        // Size ordering is a best-effort; no size field on item itself.
        result.sort((a, b) => a.name.compareTo(b.name));
    }
    return result;
  }

  /// Folders whose parent is [currentFolderId].
  List<Folder> get visibleFolders => folders
      .where((f) => f.parentFolderId == currentFolderId)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  /// Ordered breadcrumb path from root to [currentFolderId].
  List<Folder> get breadcrumbs {
    if (currentFolderId == null) return [];
    final path = <Folder>[];
    String? id = currentFolderId;
    while (id != null) {
      try {
        final folder = folders.firstWhere((f) => f.id == id);
        path.insert(0, folder);
        id = folder.parentFolderId;
      } catch (_) {
        break;
      }
    }
    return path;
  }

  LibraryState copyWith({
    List<LibraryItem>? items,
    List<LibraryItem>? trashItems,
    List<Folder>? folders,
    List<Tag>? tags,
    List<SmartCollection>? smartCollections,
    Object? currentFolderId = _sentinel,
    String? searchQuery,
    List<SearchResult>? searchResults,
    bool? isSearchMode,
    LibraryViewMode? viewMode,
    LibrarySortOrder? sortOrder,
    Set<String>? filterTagIds,
    Set<LibraryItemType>? filterTypes,
    Object? filterColorLabel = _sentinel,
    Object? filterIsFavorite = _sentinel,
    Object? activeSmartCollection = _sentinel,
    bool? isSpotlightOpen,
    bool? isLoading,
    Object? error = _sentinel,
  }) =>
      LibraryState(
        items: items ?? this.items,
        trashItems: trashItems ?? this.trashItems,
        folders: folders ?? this.folders,
        tags: tags ?? this.tags,
        smartCollections: smartCollections ?? this.smartCollections,
        currentFolderId: currentFolderId == _sentinel
            ? this.currentFolderId
            : currentFolderId as String?,
        searchQuery: searchQuery ?? this.searchQuery,
        searchResults: searchResults ?? this.searchResults,
        isSearchMode: isSearchMode ?? this.isSearchMode,
        viewMode: viewMode ?? this.viewMode,
        sortOrder: sortOrder ?? this.sortOrder,
        filterTagIds: filterTagIds ?? this.filterTagIds,
        filterTypes: filterTypes ?? this.filterTypes,
        filterColorLabel: filterColorLabel == _sentinel
            ? this.filterColorLabel
            : filterColorLabel as ColorLabel?,
        filterIsFavorite: filterIsFavorite == _sentinel
            ? this.filterIsFavorite
            : filterIsFavorite as bool?,
        activeSmartCollection: activeSmartCollection == _sentinel
            ? this.activeSmartCollection
            : activeSmartCollection as SmartCollection?,
        isSpotlightOpen: isSpotlightOpen ?? this.isSpotlightOpen,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
      );

  @override
  List<Object?> get props => [
        items,
        trashItems,
        folders,
        tags,
        smartCollections,
        currentFolderId,
        searchQuery,
        searchResults,
        isSearchMode,
        viewMode,
        sortOrder,
        filterTagIds,
        filterTypes,
        filterColorLabel,
        filterIsFavorite,
        activeSmartCollection,
        isSpotlightOpen,
        isLoading,
        error,
      ];
}

const _sentinel = Object();
