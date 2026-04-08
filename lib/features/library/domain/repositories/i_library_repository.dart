import 'package:biscuits/core/utils/result.dart';
import 'package:biscuits/features/library/domain/entities/folder.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';

/// Contract for library data persistence.
///
/// Feature-level code depends on this abstraction, allowing the
/// backing store (SharedPreferences, SQLite, cloud, etc.) to be
/// swapped transparently.
abstract class ILibraryRepository {
  /// Loads all library items.
  Future<Result<List<LibraryItem>>> loadItems();

  /// Persists the full list of [items].
  Future<Result<void>> saveItems(List<LibraryItem> items);

  /// Loads all folders.
  Future<Result<List<Folder>>> loadFolders();

  /// Persists the full list of [folders].
  Future<Result<void>> saveFolders(List<Folder> folders);

  /// Loads all tags.
  Future<Result<List<Tag>>> loadTags();

  /// Persists the full list of [tags].
  Future<Result<void>> saveTags(List<Tag> tags);
}
