import 'package:biscuits/features/canvas/domain/entities/stroke.dart';

/// Repository interface for canvas data persistence.
///
/// A full implementation backed by Isar will be provided in a later PR.
abstract class CanvasRepository {
  /// Load all strokes for [pageId].
  Future<List<Stroke>> loadStrokes(String pageId);

  /// Persist [strokes] for [pageId].
  Future<void> saveStrokes(String pageId, List<Stroke> strokes);

  /// Clear all strokes for [pageId].
  Future<void> clearStrokes(String pageId);
}

/// In-memory implementation used until the database layer is ready.
class InMemoryCanvasRepository implements CanvasRepository {
  final Map<String, List<Stroke>> _store = {};

  @override
  Future<List<Stroke>> loadStrokes(String pageId) async =>
      List.unmodifiable(_store[pageId] ?? []);

  @override
  Future<void> saveStrokes(String pageId, List<Stroke> strokes) async =>
      _store[pageId] = List.of(strokes);

  @override
  Future<void> clearStrokes(String pageId) async => _store.remove(pageId);
}
