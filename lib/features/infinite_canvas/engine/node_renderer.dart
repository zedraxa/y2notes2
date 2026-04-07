import 'package:flutter/material.dart';
import '../domain/entities/canvas_node.dart';
import 'lod_renderer.dart';

/// Orchestrates node rendering on the infinite canvas [CustomPainter].
///
/// At [LodLevel.normal] and [LodLevel.detailed] the widget layer handles
/// full rendering — this painter handles overview/coarse levels and draws
/// selection outlines for all levels.
class NodeRenderer extends CustomPainter {
  NodeRenderer({
    required this.visibleNodes,
    required this.selectedNodeIds,
    required this.zoomLevel,
    required this.worldToScreen,
    required this.worldOffset,
    required this.screenSize,
  });

  final List<CanvasNode> visibleNodes;
  final Set<String> selectedNodeIds;
  final double zoomLevel;
  final Offset Function(Offset) worldToScreen;
  final Offset worldOffset;
  final Size screenSize;

  final LodRenderer _lod = const LodRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    final level = LodRenderer.levelFor(zoomLevel);

    // Draw grid dots in detailed mode.
    _lod.paintGrid(
      canvas: canvas,
      screenSize: screenSize,
      worldOffset: worldOffset,
      zoomLevel: zoomLevel,
    );

    // In overview / coarse, paint placeholders.
    if (level == LodLevel.overview || level == LodLevel.coarse) {
      for (final node in visibleNodes) {
        final tl = worldToScreen(node.worldBounds.topLeft);
        final br = worldToScreen(node.worldBounds.bottomRight);
        final screenRect = Rect.fromPoints(tl, br);
        _lod.paintNodePlaceholder(
          canvas: canvas,
          node: node,
          lod: level,
          screenRect: screenRect,
          isSelected: selectedNodeIds.contains(node.id),
        );
      }
    } else {
      // In normal/detailed mode only draw selection outlines here;
      // actual content is rendered by Flutter widgets.
      for (final node in visibleNodes) {
        if (selectedNodeIds.contains(node.id)) {
          final tl = worldToScreen(node.worldBounds.topLeft);
          final br = worldToScreen(node.worldBounds.bottomRight);
          final rect = Rect.fromPoints(tl, br);
          canvas.drawRect(
            rect.inflate(2),
            Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          // Draw resize handles.
          _drawHandles(canvas, rect);
        }
      }
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final point in _handlePoints(rect)) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 8, height: 8),
        handlePaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 8, height: 8),
        borderPaint,
      );
    }
  }

  List<Offset> _handlePoints(Rect r) => [
        r.topLeft,
        Offset(r.center.dx, r.top),
        r.topRight,
        Offset(r.right, r.center.dy),
        r.bottomRight,
        Offset(r.center.dx, r.bottom),
        r.bottomLeft,
        Offset(r.left, r.center.dy),
      ];

  @override
  bool shouldRepaint(NodeRenderer old) =>
      old.zoomLevel != zoomLevel ||
      old.worldOffset != worldOffset ||
      old.selectedNodeIds != selectedNodeIds ||
      old.visibleNodes.length != visibleNodes.length;
}
