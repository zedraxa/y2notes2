import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/entities/canvas_edge.dart';
import '../domain/entities/canvas_node.dart';

/// Available automatic layout algorithms.
enum LayoutAlgorithm {
  /// Central root node with children radiating outward.
  radial,

  /// Top-down or left-right tree layout.
  tree,

  /// Physics simulation — nodes repel each other, edges attract.
  forceDirected,

  /// Snap all nodes to a regular grid.
  grid,

  /// Left-to-right flow.
  horizontal,

  /// Top-to-bottom flow.
  vertical,

  /// No automatic layout; nodes stay where the user placed them.
  freeform,
}

/// Computes world-space positions for nodes according to a [LayoutAlgorithm].
///
/// Returns a map of node ID → new [Offset] (world position / centre).
/// Does **not** mutate any state — callers apply the result.
class AutoLayout {
  const AutoLayout._();

  /// Arrange [nodes] connected by [edges] using [algorithm].
  ///
  /// [center] is the world-space origin of the layout result.
  /// [spacing] is the preferred distance between node centres.
  static Map<String, Offset> layout({
    required List<CanvasNode> nodes,
    required List<CanvasEdge> edges,
    required LayoutAlgorithm algorithm,
    Offset center = Offset.zero,
    double spacing = 200.0,
  }) {
    if (nodes.isEmpty) return {};

    switch (algorithm) {
      case LayoutAlgorithm.radial:
        return _radial(nodes, edges, center, spacing);
      case LayoutAlgorithm.tree:
        return _tree(nodes, edges, center, spacing);
      case LayoutAlgorithm.forceDirected:
        return _forceDirected(nodes, edges, center, spacing);
      case LayoutAlgorithm.grid:
        return _grid(nodes, center, spacing);
      case LayoutAlgorithm.horizontal:
        return _horizontal(nodes, center, spacing);
      case LayoutAlgorithm.vertical:
        return _vertical(nodes, center, spacing);
      case LayoutAlgorithm.freeform:
        return {for (final n in nodes) n.id: n.worldPosition};
    }
  }

  // ── Radial ────────────────────────────────────────────────────────────────

  static Map<String, Offset> _radial(
    List<CanvasNode> nodes,
    List<CanvasEdge> edges,
    Offset center,
    double spacing,
  ) {
    final result = <String, Offset>{};
    if (nodes.isEmpty) return result;

    // Find root: node with most outgoing edges, or first node.
    final outDegree = <String, int>{};
    for (final e in edges) {
      outDegree[e.sourceNodeId] = (outDegree[e.sourceNodeId] ?? 0) + 1;
    }
    final root = nodes.reduce(
      (a, b) => (outDegree[a.id] ?? 0) >= (outDegree[b.id] ?? 0) ? a : b,
    );

    result[root.id] = center;

    final children = nodes.where((n) => n.id != root.id).toList();
    if (children.isEmpty) return result;

    final ringCount = math.max(1, (math.sqrt(children.length)).ceil());
    int placed = 0;
    for (int ring = 1; ring <= ringCount && placed < children.length; ring++) {
      final radius = spacing * ring;
      final count = math.min(children.length - placed, ring * 6);
      for (int i = 0; i < count; i++) {
        final angle = (2 * math.pi * i) / count;
        result[children[placed].id] = center +
            Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        placed++;
      }
    }
    // Any remaining nodes.
    while (placed < children.length) {
      final angle = (2 * math.pi * placed) / children.length;
      final radius = spacing * ringCount.toDouble();
      result[children[placed].id] = center +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          );
      placed++;
    }
    return result;
  }

  // ── Tree ─────────────────────────────────────────────────────────────────

  static Map<String, Offset> _tree(
    List<CanvasNode> nodes,
    List<CanvasEdge> edges,
    Offset center,
    double spacing,
  ) {
    // Build adjacency — find root (node with no incoming edges).
    final hasParent = <String>{};
    final children = <String, List<String>>{};
    for (final e in edges) {
      hasParent.add(e.targetNodeId);
      children.putIfAbsent(e.sourceNodeId, () => []).add(e.targetNodeId);
    }
    final nodeIds = nodes.map((n) => n.id).toSet();
    final roots = nodeIds.where((id) => !hasParent.contains(id)).toList();
    if (roots.isEmpty) roots.add(nodes.first.id);

    final result = <String, Offset>{};
    double x = center.dx;

    void placeSubtree(String id, double y, int depth) {
      final kids = children[id] ?? [];
      if (kids.isEmpty) {
        result[id] = Offset(x, y + depth * spacing);
        x += spacing;
        return;
      }
      final startX = x;
      for (final kid in kids) {
        placeSubtree(kid, y, depth + 1);
      }
      final endX = x;
      result[id] = Offset(
        (startX + endX) / 2 - spacing / 2,
        y + depth * spacing,
      );
    }

    for (final r in roots) {
      placeSubtree(r, center.dy, 0);
    }

    // Place any isolated nodes at the end.
    for (final n in nodes) {
      if (!result.containsKey(n.id)) {
        result[n.id] = Offset(x, center.dy);
        x += spacing;
      }
    }
    return result;
  }

  // ── Force-directed ────────────────────────────────────────────────────────

  static Map<String, Offset> _forceDirected(
    List<CanvasNode> nodes,
    List<CanvasEdge> edges,
    Offset center,
    double spacing,
  ) {
    // Initialise positions in a circle.
    final pos = <String, Offset>{};
    for (int i = 0; i < nodes.length; i++) {
      final angle = (2 * math.pi * i) / nodes.length;
      pos[nodes[i].id] = Offset(
        center.dx + math.cos(angle) * spacing,
        center.dy + math.sin(angle) * spacing,
      );
    }

    final edgePairs = edges
        .map((e) => (e.sourceNodeId, e.targetNodeId))
        .where((p) => pos.containsKey(p.$1) && pos.containsKey(p.$2))
        .toList();

    const iterations = 100;
    double temperature = spacing * 2;
    final area = spacing * spacing * nodes.length;
    final k = math.sqrt(area / math.max(1, nodes.length));

    for (int iter = 0; iter < iterations; iter++) {
      final disp = <String, Offset>{for (final n in nodes) n.id: Offset.zero};

      // Repulsion.
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final u = nodes[i].id;
          final v = nodes[j].id;
          final delta = pos[u]! - pos[v]!;
          final dist = math.max(delta.distance, 0.01);
          final force = k * k / dist;
          final unit = delta / dist;
          disp[u] = disp[u]! + unit * force;
          disp[v] = disp[v]! - unit * force;
        }
      }

      // Attraction along edges.
      for (final (u, v) in edgePairs) {
        final delta = pos[u]! - pos[v]!;
        final dist = math.max(delta.distance, 0.01);
        final force = dist * dist / k;
        final unit = delta / dist;
        disp[u] = disp[u]! - unit * force;
        disp[v] = disp[v]! + unit * force;
      }

      // Apply displacement capped by temperature.
      for (final n in nodes) {
        final d = disp[n.id]!;
        final mag = math.max(d.distance, 0.01);
        pos[n.id] = pos[n.id]! + d / mag * math.min(mag, temperature);
      }

      temperature *= 0.9;
    }

    return pos;
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  static Map<String, Offset> _grid(
    List<CanvasNode> nodes,
    Offset center,
    double spacing,
  ) {
    final cols = math.max(1, math.sqrt(nodes.length).ceil());
    final result = <String, Offset>{};
    for (int i = 0; i < nodes.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      result[nodes[i].id] = Offset(
        center.dx + col * spacing,
        center.dy + row * spacing,
      );
    }
    return result;
  }

  // ── Horizontal ────────────────────────────────────────────────────────────

  static Map<String, Offset> _horizontal(
    List<CanvasNode> nodes,
    Offset center,
    double spacing,
  ) {
    final result = <String, Offset>{};
    for (int i = 0; i < nodes.length; i++) {
      result[nodes[i].id] = Offset(center.dx + i * spacing, center.dy);
    }
    return result;
  }

  // ── Vertical ──────────────────────────────────────────────────────────────

  static Map<String, Offset> _vertical(
    List<CanvasNode> nodes,
    Offset center,
    double spacing,
  ) {
    final result = <String, Offset>{};
    for (int i = 0; i < nodes.length; i++) {
      result[nodes[i].id] = Offset(center.dx, center.dy + i * spacing);
    }
    return result;
  }
}
