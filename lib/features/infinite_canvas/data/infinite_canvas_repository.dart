import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/canvas_node.dart';
import '../domain/entities/infinite_canvas_document.dart';

/// Persists and loads [InfiniteCanvasDocument]s using [SharedPreferences].
///
/// Auto-save is triggered by the caller (BLoC) after a debounce delay.
class InfiniteCanvasRepository {
  InfiniteCanvasRepository();

  static const String _prefix = 'infinite_canvas_';

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Save [document] to persistent storage.
  Future<void> save(InfiniteCanvasDocument document) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(document.toJson());
    await prefs.setString('$_prefix${document.id}', json);
  }

  /// Load a document by [id].  Returns null if not found.
  Future<InfiniteCanvasDocument?> load(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$id');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final doc = InfiniteCanvasDocument.fromJson(map);

      // Deserialise nodes (requires type dispatch).
      final rawNodes =
          (map['nodes'] as Map<String, dynamic>?) ?? {};
      final nodes = <String, CanvasNode>{};
      for (final entry in rawNodes.entries) {
        final nodeMap = entry.value as Map<String, dynamic>;
        final node = _deserialiseNode(nodeMap);
        if (node != null) nodes[entry.key] = node;
      }

      return doc.copyWith(nodes: nodes);
    } catch (_) {
      return null;
    }
  }

  /// Delete a document by [id].
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }

  /// Return all saved document IDs.
  Future<List<String>> listIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .map((k) => k.substring(_prefix.length))
        .toList();
  }

  // ── Node deserialisation ──────────────────────────────────────────────────

  CanvasNode? _deserialiseNode(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? '';
    final pos = _parseOffset(map['worldPosition'] as Map?);
    final size = _parseSize(map['worldSize'] as Map?);
    final rotation = (map['rotation'] as num?)?.toDouble() ?? 0.0;
    final zIndex = (map['zIndex'] as num?)?.toInt() ?? 0;
    final isLocked = map['isLocked'] as bool? ?? false;
    final createdAt =
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now();
    final id = map['id'] as String? ?? '';

    switch (type) {
      case 'TextCardNode':
        return TextCardNode(
          id: id,
          worldPosition: pos,
          worldSize: size,
          rotation: rotation,
          zIndex: zIndex,
          isLocked: isLocked,
          createdAt: createdAt,
          text: map['text'] as String? ?? '',
          fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16,
        );
      case 'StickyNoteNode':
        return StickyNoteNode(
          id: id,
          worldPosition: pos,
          worldSize: size,
          rotation: rotation,
          zIndex: zIndex,
          isLocked: isLocked,
          createdAt: createdAt,
          text: map['text'] as String? ?? '',
        );
      case 'StrokeRegionNode':
        return StrokeRegionNode(
          id: id,
          worldPosition: pos,
          worldSize: size,
          rotation: rotation,
          zIndex: zIndex,
          isLocked: isLocked,
          createdAt: createdAt,
          title: map['title'] as String?,
        );
      case 'FrameNode':
        return FrameNode(
          id: id,
          worldPosition: pos,
          worldSize: size,
          rotation: rotation,
          zIndex: zIndex,
          isLocked: isLocked,
          createdAt: createdAt,
          label: map['label'] as String? ?? 'Frame',
        );
      case 'GroupNode':
        return GroupNode(
          id: id,
          worldPosition: pos,
          worldSize: size,
          rotation: rotation,
          zIndex: zIndex,
          isLocked: isLocked,
          createdAt: createdAt,
          childNodeIds: (map['childNodeIds'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
        );
      default:
        return null;
    }
  }

  static Offset _parseOffset(Map? map) {
    if (map == null) return Offset.zero;
    return Offset(
      (map['dx'] as num?)?.toDouble() ?? 0,
      (map['dy'] as num?)?.toDouble() ?? 0,
    );
  }

  static Size _parseSize(Map? map) {
    if (map == null) return const Size(200, 150);
    return Size(
      (map['width'] as num?)?.toDouble() ?? 200,
      (map['height'] as num?)?.toDouble() ?? 150,
    );
  }
}
