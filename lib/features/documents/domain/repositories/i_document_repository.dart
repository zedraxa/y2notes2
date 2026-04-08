import 'package:biscuits/core/utils/result.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';

/// Contract for notebook persistence.
///
/// Feature-level code depends on this abstraction rather than on a
/// concrete [SharedPreferences]-based implementation, enabling:
///
/// * Easy swapping between local storage, cloud, or in-memory backends.
/// * Straightforward mocking in unit / BLoC tests.
abstract class IDocumentRepository {
  /// Persists [notebook] to the backing store.
  Future<Result<void>> saveNotebook(Notebook notebook);

  /// Loads a previously saved notebook by its [id], or returns `null`
  /// inside a [Success] when none exists.
  Future<Result<Notebook?>> loadNotebook({String? id});

  /// Removes the persisted notebook identified by [id].
  Future<Result<void>> deleteNotebook({String? id});
}
