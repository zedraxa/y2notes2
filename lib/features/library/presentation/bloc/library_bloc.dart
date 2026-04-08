import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuits/features/library/data/library_repository.dart';
import 'package:biscuits/features/library/domain/entities/folder.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/smart_collection.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';
import 'package:biscuits/features/library/engine/search_engine.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';

/// BLoC that manages the entire library feature.
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({required this.repository})
      : super(const LibraryState(isLoading: true)) {
    on<LoadLibrary>(_onLoad);
    on<CreateFolder>(_onCreateFolder);
    on<RenameFolder>(_onRenameFolder);
    on<DeleteFolder>(_onDeleteFolder);
    on<NavigateToFolder>(_onNavigateToFolder);
    on<CreateItem>(_onCreateItem);
    on<RenameItem>(_onRenameItem);
    on<MoveToFolder>(_onMoveToFolder);
    on<DeleteItem>(_onDeleteItem);
    on<RestoreItem>(_onRestoreItem);
    on<PermanentlyDeleteItem>(_onPermanentlyDeleteItem);
    on<EmptyTrash>(_onEmptyTrash);
    on<ToggleFavorite>(_onToggleFavorite);
    on<SetColorLabel>(_onSetColorLabel);
    on<SetNotebookCover>(_onSetNotebookCover);
    on<CreateTag>(_onCreateTag);
    on<UpdateTag>(_onUpdateTag);
    on<DeleteTag>(_onDeleteTag);
    on<AddTagToItem>(_onAddTagToItem);
    on<RemoveTagFromItem>(_onRemoveTagFromItem);
    on<SearchLibrary>(_onSearch);
    on<ClearSearch>(_onClearSearch);
    on<OpenSpotlight>(_onOpenSpotlight);
    on<CloseSpotlight>(_onCloseSpotlight);
    on<SortBy>(_onSortBy);
    on<FilterBy>(_onFilterBy);
    on<ClearFilters>(_onClearFilters);
    on<FilterBySmartCollection>(_onFilterBySmartCollection);
    on<ToggleViewMode>(_onToggleViewMode);
  }

  final LibraryRepository repository;
  final _searchEngine = SearchEngine();
  final _uuid = const Uuid();

  /// Internal list that includes trashed items (not exposed via state.items).
  List<LibraryItem> _allItems = [];

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(LoadLibrary event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await repository.loadItems();
      final folders = await repository.loadFolders();
      final tags = await repository.loadTags();

      _allItems = items;

      // Rebuild search index.
      final nonTrash = items.where((i) => !i.isInTrash).toList();
      final trashed = items.where((i) => i.isInTrash).toList();
      _searchEngine.rebuildIndex(nonTrash);

      emit(state.copyWith(
        items: nonTrash,
        trashItems: trashed,
        folders: folders,
        tags: tags,
        smartCollections: builtInSmartCollections,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // ── Folders ───────────────────────────────────────────────────────────────

  void _onCreateFolder(CreateFolder event, Emitter<LibraryState> emit) {
    final folder = Folder(
      id: _uuid.v4(),
      name: event.name,
      parentFolderId: event.parentFolderId ?? state.currentFolderId,
      emoji: event.emoji,
    );
    final folders = [...state.folders, folder];
    _persistFolders(folders);
    emit(state.copyWith(folders: folders));
  }

  void _onRenameFolder(RenameFolder event, Emitter<LibraryState> emit) {
    final folders = state.folders.map((f) {
      if (f.id == event.folderId) return f.copyWith(name: event.newName);
      return f;
    }).toList();
    _persistFolders(folders);
    emit(state.copyWith(folders: folders));
  }

  void _onDeleteFolder(DeleteFolder event, Emitter<LibraryState> emit) {
    // Move all items inside the folder to trash.
    final updated = _allItems.map((item) {
      if (item.folderId == event.folderId && !item.isInTrash) {
        return item.copyWith(
            isInTrash: true, trashedAt: DateTime.now());
      }
      return item;
    }).toList();
    _allItems = updated;
    _persistItems(updated);

    final folders = state.folders.where((f) => f.id != event.folderId).toList();
    _persistFolders(folders);

    emit(_withItems(state, folders: folders));
  }

  void _onNavigateToFolder(NavigateToFolder event, Emitter<LibraryState> emit) {
    // Passing null correctly clears currentFolderId (navigates to root).
    emit(state.copyWith(currentFolderId: event.folderId));
  }

  // ── Items ─────────────────────────────────────────────────────────────────

  void _onCreateItem(CreateItem event, Emitter<LibraryState> emit) {
    final item = LibraryItem(
      id: event.id ?? _uuid.v4(),
      type: event.type,
      name: event.name,
      folderId: event.folderId ?? state.currentFolderId,
    );
    _allItems = [..._allItems, item];
    _persistItems(_allItems);
    _searchEngine.indexItem(item);
    emit(_withItems(state));
  }

  void _onRenameItem(RenameItem event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        final updated = item.copyWith(name: event.newName);
        _searchEngine.indexItem(updated);
        return updated;
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  void _onMoveToFolder(MoveToFolder event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        // Passing null moves item to root (folderId = null).
        return item.copyWith(folderId: event.folderId);
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  void _onDeleteItem(DeleteItem event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(isInTrash: true, trashedAt: DateTime.now());
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    _searchEngine.removeFromIndex(event.itemId);
    emit(_withItems(state));
  }

  void _onRestoreItem(RestoreItem event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        final restored = item.copyWith(
            isInTrash: false, trashedAt: null);
        _searchEngine.indexItem(restored);
        return restored;
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  void _onPermanentlyDeleteItem(
      PermanentlyDeleteItem event, Emitter<LibraryState> emit) {
    _allItems = _allItems.where((i) => i.id != event.itemId).toList();
    _persistItems(_allItems);
    _searchEngine.removeFromIndex(event.itemId);
    emit(_withItems(state));
  }

  void _onEmptyTrash(EmptyTrash event, Emitter<LibraryState> emit) {
    _allItems = _allItems.where((i) => !i.isInTrash).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  void _onToggleFavorite(ToggleFavorite event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  void _onSetColorLabel(SetColorLabel event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        // Passing null clears the colour label.
        return item.copyWith(colorLabel: event.colorLabel);
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  void _onSetNotebookCover(SetNotebookCover event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(
          coverColor: event.coverColor,
          coverMaterial: event.coverMaterial,
          coverPattern: event.coverPattern,
          coverEmblem: event.coverEmblem,
        );
      }
      return item;
    }).toList();
    _persistItems(_allItems);
    emit(_withItems(state));
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  void _onCreateTag(CreateTag event, Emitter<LibraryState> emit) {
    final tags = [...state.tags, event.tag];
    _persistTags(tags);
    emit(state.copyWith(tags: tags));
  }

  void _onUpdateTag(UpdateTag event, Emitter<LibraryState> emit) {
    final tags = state.tags.map((t) {
      if (t.id == event.tag.id) return event.tag;
      return t;
    }).toList();
    _persistTags(tags);
    emit(state.copyWith(tags: tags));
  }

  void _onDeleteTag(DeleteTag event, Emitter<LibraryState> emit) {
    final tags = state.tags.where((t) => t.id != event.tagId).toList();
    _persistTags(tags);

    // Remove tag from all items.
    _allItems = _allItems.map((item) {
      if (item.tagIds.contains(event.tagId)) {
        return item.copyWith(
            tagIds: item.tagIds.where((id) => id != event.tagId).toList());
      }
      return item;
    }).toList();
    _persistItems(_allItems);

    emit(_withItems(state, tags: tags));
  }

  void _onAddTagToItem(AddTagToItem event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId && !item.tagIds.contains(event.tagId)) {
        return item.copyWith(tagIds: [...item.tagIds, event.tagId]);
      }
      return item;
    }).toList();
    _persistItems(_allItems);

    // Increment usageCount.
    final tags = state.tags.map((t) {
      if (t.id == event.tagId) return t.copyWith(usageCount: t.usageCount + 1);
      return t;
    }).toList();
    _persistTags(tags);

    emit(_withItems(state, tags: tags));
  }

  void _onRemoveTagFromItem(RemoveTagFromItem event, Emitter<LibraryState> emit) {
    _allItems = _allItems.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(
            tagIds: item.tagIds.where((id) => id != event.tagId).toList());
      }
      return item;
    }).toList();
    _persistItems(_allItems);

    final tags = state.tags.map((t) {
      if (t.id == event.tagId && t.usageCount > 0) {
        return t.copyWith(usageCount: t.usageCount - 1);
      }
      return t;
    }).toList();
    _persistTags(tags);

    emit(_withItems(state, tags: tags));
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _onSearch(SearchLibrary event, Emitter<LibraryState> emit) {
    final results = _searchEngine.search(event.query);
    emit(state.copyWith(
      searchQuery: event.query,
      searchResults: results,
    ));
  }

  void _onClearSearch(ClearSearch event, Emitter<LibraryState> emit) {
    emit(state.copyWith(
      searchQuery: '',
      searchResults: [],
    ));
  }

  void _onOpenSpotlight(OpenSpotlight event, Emitter<LibraryState> emit) {
    emit(state.copyWith(isSpotlightOpen: true));
  }

  void _onCloseSpotlight(CloseSpotlight event, Emitter<LibraryState> emit) {
    emit(state.copyWith(isSpotlightOpen: false));
  }

  // ── View options ──────────────────────────────────────────────────────────

  void _onSortBy(SortBy event, Emitter<LibraryState> emit) {
    emit(state.copyWith(sortOrder: event.order));
  }

  void _onFilterBy(FilterBy event, Emitter<LibraryState> emit) {
    emit(state.copyWith(
      filterTagIds: event.tagIds ?? state.filterTagIds,
      filterTypes: event.types ?? state.filterTypes,
      // Passing null explicitly clears the scalar filter (null != _sentinel
      // in copyWith). Callers must include existing values when they only
      // want to change one field; see FilterPanel in sort_filter_bar.dart.
      filterColorLabel: event.colorLabel,
      filterIsFavorite: event.isFavorite,
    ));
  }

  void _onClearFilters(ClearFilters event, Emitter<LibraryState> emit) {
    emit(state.copyWith(
      filterTagIds: {},
      filterTypes: {},
      // Pass null explicitly to clear nullable fields (null != _sentinel in
      // LibraryState.copyWith, so they will be set to null correctly).
      filterColorLabel: null,
      filterIsFavorite: null,
      activeSmartCollection: null,
    ));
  }

  void _onFilterBySmartCollection(
      FilterBySmartCollection event, Emitter<LibraryState> emit) {
    emit(state.copyWith(activeSmartCollection: event.collection));
  }

  void _onToggleViewMode(ToggleViewMode event, Emitter<LibraryState> emit) {
    emit(state.copyWith(
      viewMode: state.viewMode == LibraryViewMode.grid
          ? LibraryViewMode.list
          : LibraryViewMode.grid,
    ));
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  Future<void> _persistItems(List<LibraryItem> items) =>
      repository.saveItems(items);

  Future<void> _persistFolders(List<Folder> folders) =>
      repository.saveFolders(folders);

  Future<void> _persistTags(List<Tag> tags) => repository.saveTags(tags);

  /// Convenience method to emit updated items + trash in one call.
  LibraryState _withItems(LibraryState s, {List<Tag>? tags, List<Folder>? folders}) {
    final nonTrash = _allItems.where((i) => !i.isInTrash).toList();
    final trashed = _allItems.where((i) => i.isInTrash).toList();
    return s.copyWith(
      items: nonTrash,
      trashItems: trashed,
      tags: tags,
      folders: folders,
    );
  }
}
