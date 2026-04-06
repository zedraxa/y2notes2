/// Stub storage service for local database (Isar).
///
/// This is a placeholder that outlines the interface. A full Isar
/// implementation will be added in a future PR.
abstract class StorageService {
  /// Initialize the storage backend.
  Future<void> init();

  /// Persist raw JSON-serializable data by [key].
  Future<void> save(String key, Map<String, dynamic> data);

  /// Load previously persisted data by [key].
  Future<Map<String, dynamic>?> load(String key);

  /// Delete data associated with [key].
  Future<void> delete(String key);

  /// Clear all stored data.
  Future<void> clearAll();
}

/// In-memory implementation used until Isar is integrated.
class InMemoryStorageService implements StorageService {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    _store[key] = Map.unmodifiable(data);
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async => _store[key];

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> clearAll() async => _store.clear();
}
