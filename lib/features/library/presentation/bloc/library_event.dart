import 'package:equatable/equatable.dart';
import 'package:biscuits/features/library/domain/entities/folder.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/smart_collection.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

// ── Loading ──────────────────────────────────────────────────────────────────

/// Load all library data from the repository.
class LoadLibrary extends LibraryEvent {
  const LoadLibrary();
}

// ── Folder management ────────────────────────────────────────────────────────

class CreateFolder extends LibraryEvent {
  const CreateFolder({required this.name, this.parentFolderId, this.emoji});
  final String name;
  final String? parentFolderId;
  final String? emoji;
  @override
  List<Object?> get props => [name, parentFolderId, emoji];
}

class RenameFolder extends LibraryEvent {
  const RenameFolder({required this.folderId, required this.newName});
  final String folderId;
  final String newName;
  @override
  List<Object?> get props => [folderId, newName];
}

class DeleteFolder extends LibraryEvent {
  const DeleteFolder(this.folderId);
  final String folderId;
  @override
  List<Object?> get props => [folderId];
}

class NavigateToFolder extends LibraryEvent {
  /// `null` navigates to root.
  const NavigateToFolder(this.folderId);
  final String? folderId;
  @override
  List<Object?> get props => [folderId];
}

// ── Item management ───────────────────────────────────────────────────────────

class CreateItem extends LibraryEvent {
  const CreateItem({required this.name, required this.type, this.folderId});
  final String name;
  final LibraryItemType type;
  final String? folderId;
  @override
  List<Object?> get props => [name, type, folderId];
}

class RenameItem extends LibraryEvent {
  const RenameItem({required this.itemId, required this.newName});
  final String itemId;
  final String newName;
  @override
  List<Object?> get props => [itemId, newName];
}

class MoveToFolder extends LibraryEvent {
  const MoveToFolder({required this.itemId, required this.folderId});
  final String itemId;
  final String? folderId;
  @override
  List<Object?> get props => [itemId, folderId];
}

class DeleteItem extends LibraryEvent {
  const DeleteItem(this.itemId);
  final String itemId;
  @override
  List<Object?> get props => [itemId];
}

class RestoreItem extends LibraryEvent {
  const RestoreItem(this.itemId);
  final String itemId;
  @override
  List<Object?> get props => [itemId];
}

class PermanentlyDeleteItem extends LibraryEvent {
  const PermanentlyDeleteItem(this.itemId);
  final String itemId;
  @override
  List<Object?> get props => [itemId];
}

class EmptyTrash extends LibraryEvent {
  const EmptyTrash();
}

class ToggleFavorite extends LibraryEvent {
  const ToggleFavorite(this.itemId);
  final String itemId;
  @override
  List<Object?> get props => [itemId];
}

class SetColorLabel extends LibraryEvent {
  const SetColorLabel({required this.itemId, this.colorLabel});
  final String itemId;
  final ColorLabel? colorLabel;
  @override
  List<Object?> get props => [itemId, colorLabel];
}

/// Update the cover appearance of a notebook library item.
class SetNotebookCover extends LibraryEvent {
  const SetNotebookCover({
    required this.itemId,
    required this.coverColor,
    required this.coverMaterial,
  });
  final String itemId;
  /// ARGB color value for the cover.
  final int coverColor;
  /// [CoverMaterial.name] string.
  final String coverMaterial;
  @override
  List<Object?> get props => [itemId, coverColor, coverMaterial];
}

// ── Tag management ────────────────────────────────────────────────────────────

class CreateTag extends LibraryEvent {
  const CreateTag({required this.tag});
  final Tag tag;
  @override
  List<Object?> get props => [tag];
}

class UpdateTag extends LibraryEvent {
  const UpdateTag({required this.tag});
  final Tag tag;
  @override
  List<Object?> get props => [tag];
}

class DeleteTag extends LibraryEvent {
  const DeleteTag(this.tagId);
  final String tagId;
  @override
  List<Object?> get props => [tagId];
}

class AddTagToItem extends LibraryEvent {
  const AddTagToItem({required this.itemId, required this.tagId});
  final String itemId;
  final String tagId;
  @override
  List<Object?> get props => [itemId, tagId];
}

class RemoveTagFromItem extends LibraryEvent {
  const RemoveTagFromItem({required this.itemId, required this.tagId});
  final String itemId;
  final String tagId;
  @override
  List<Object?> get props => [itemId, tagId];
}

// ── Search ────────────────────────────────────────────────────────────────────

class SearchLibrary extends LibraryEvent {
  const SearchLibrary(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class ClearSearch extends LibraryEvent {
  const ClearSearch();
}

class OpenSpotlight extends LibraryEvent {
  const OpenSpotlight();
}

class CloseSpotlight extends LibraryEvent {
  const CloseSpotlight();
}

// ── View options ──────────────────────────────────────────────────────────────

class SortBy extends LibraryEvent {
  const SortBy(this.order);
  final LibrarySortOrder order;
  @override
  List<Object?> get props => [order];
}

class FilterBy extends LibraryEvent {
  const FilterBy({this.tagIds, this.types, this.colorLabel, this.isFavorite});
  final Set<String>? tagIds;
  final Set<LibraryItemType>? types;
  final ColorLabel? colorLabel;
  final bool? isFavorite;
  @override
  List<Object?> get props => [tagIds, types, colorLabel, isFavorite];
}

class ClearFilters extends LibraryEvent {
  const ClearFilters();
}

/// Activates (or clears) a smart collection filter.
///
/// Pass `null` to clear the active smart collection.
class FilterBySmartCollection extends LibraryEvent {
  const FilterBySmartCollection(this.collection);
  final SmartCollection? collection;
  @override
  List<Object?> get props => [collection];
}

class ToggleViewMode extends LibraryEvent {
  const ToggleViewMode();
}

// ── Enumerations used by events ───────────────────────────────────────────────

enum LibrarySortOrder { dateModified, dateCreated, name, size }

enum LibraryViewMode { grid, list }
