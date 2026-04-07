import 'package:flutter/material.dart';
import '../../../domain/entities/canvas_edge.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../../engine/edge_renderer.dart';

/// [CustomPainter] that draws all canvas edges.
class EdgePainter extends CustomPainter {
  EdgePainter({
    required this.edges,
    required this.nodeMap,
    required this.worldToScreen,
    required this.zoomLevel,
    this.selectedEdgeId,
  });

  final List<CanvasEdge> edges;
  final Map<String, CanvasNode> nodeMap;
  final Offset Function(Offset) worldToScreen;
  final double zoomLevel;
  final String? selectedEdgeId;

  static const EdgeRenderer _renderer = EdgeRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.paint(
      canvas: canvas,
      edges: edges,
      nodeMap: nodeMap,
      worldToScreen: worldToScreen,
      selectedEdgeId: selectedEdgeId,
      zoomLevel: zoomLevel,
    );
  }

  @override
  bool shouldRepaint(EdgePainter old) =>
      old.edges != edges ||
      old.zoomLevel != zoomLevel ||
      old.selectedEdgeId != selectedEdgeId;
}
