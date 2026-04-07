import 'package:uuid/uuid.dart';
import 'canvas_edge.dart';
import 'canvas_node.dart';

/// The top-level document model for an infinite canvas session.
///
/// Holds all [nodes], [edges], and the last-known viewport.
class InfiniteCanvasDocument {
  InfiniteCanvasDocument({
    required this.id,
    required this.title,
    required this.nodes,
    required this.edges,
    this.viewportOffsetDx = 0.0,
    this.viewportOffsetDy = 0.0,
    this.zoomLevel = 1.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a blank document with a generated UUID.
  factory InfiniteCanvasDocument.blank({String title = 'Untitled Canvas'}) =>
      InfiniteCanvasDocument(
        id: const Uuid().v4(),
        title: title,
        nodes: const {},
        edges: const {},
      );

  final String id;
  final String title;

  /// All nodes keyed by their ID.
  final Map<String, CanvasNode> nodes;

  /// All edges keyed by their ID.
  final Map<String, CanvasEdge> edges;

  /// Persisted viewport pan position (X component).
  final double viewportOffsetDx;

  /// Persisted viewport pan position (Y component).
  final double viewportOffsetDy;

  /// Persisted zoom level.
  final double zoomLevel;

  final DateTime createdAt;
  final DateTime updatedAt;

  InfiniteCanvasDocument copyWith({
    String? title,
    Map<String, CanvasNode>? nodes,
    Map<String, CanvasEdge>? edges,
    double? viewportOffsetDx,
    double? viewportOffsetDy,
    double? zoomLevel,
  }) =>
      InfiniteCanvasDocument(
        id: id,
        title: title ?? this.title,
        nodes: nodes ?? this.nodes,
        edges: edges ?? this.edges,
        viewportOffsetDx: viewportOffsetDx ?? this.viewportOffsetDx,
        viewportOffsetDy: viewportOffsetDy ?? this.viewportOffsetDy,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
        'edges': edges.map((k, v) => MapEntry(k, v.toJson())),
        'viewportOffsetDx': viewportOffsetDx,
        'viewportOffsetDy': viewportOffsetDy,
        'zoomLevel': zoomLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InfiniteCanvasDocument.fromJson(Map<String, dynamic> json) {
    final rawEdges = json['edges'] as Map<String, dynamic>? ?? {};
    return InfiniteCanvasDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      nodes: const {}, // Nodes require type dispatch — handled by repository.
      edges: rawEdges.map(
        (k, v) => MapEntry(k, CanvasEdge.fromJson(v as Map<String, dynamic>)),
      ),
      viewportOffsetDx:
          (json['viewportOffsetDx'] as num?)?.toDouble() ?? 0.0,
      viewportOffsetDy:
          (json['viewportOffsetDy'] as num?)?.toDouble() ?? 0.0,
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
