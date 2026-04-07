import 'package:flutter/material.dart';
import '../domain/entities/canvas_node.dart';

/// Classifies a zoom level into a rendering fidelity tier.
enum LodLevel {
  /// Zoom < 0.1 — only coloured rectangles.
  overview,

  /// 0.1 ≤ zoom < 0.5 — outlines and title text.
  coarse,

  /// 0.5 ≤ zoom < 2.0 — full detail.
  normal,

  /// zoom ≥ 2.0 — pixel-perfect; show grid dots.
  detailed,
}

/// Computes the [LodLevel] for a given [zoomLevel] and provides helpers for
/// rendering nodes at the appropriate fidelity.
class LodRenderer {
  const LodRenderer();

  // ── LOD classification ─────────────────────────────────────────────────────

  /// Return the correct [LodLevel] for [zoom].
  static LodLevel levelFor(double zoom) {
    if (zoom < 0.1) return LodLevel.overview;
    if (zoom < 0.5) return LodLevel.coarse;
    if (zoom < 2.0) return LodLevel.normal;
    return LodLevel.detailed;
  }

  // ── Grid dot painting ──────────────────────────────────────────────────────

  /// Paint a subtle dot grid when in [LodLevel.detailed] mode.
  ///
  /// [screenSize] is the visible viewport in screen pixels.
  /// [worldOffset] and [zoomLevel] define the current transform.
  void paintGrid({
    required Canvas canvas,
    required Size screenSize,
    required Offset worldOffset,
    required double zoomLevel,
    Color dotColor = const Color(0x33AAAAAA),
    double gridWorldSpacing = 50.0,
  }) {
    if (levelFor(zoomLevel) != LodLevel.detailed) return;

    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // World coordinate of top-left corner of screen.
    final cx = screenSize.width / 2;
    final cy = screenSize.height / 2;

    final worldLeft = worldOffset.dx - cx / zoomLevel;
    final worldTop = worldOffset.dy - cy / zoomLevel;
    final worldRight = worldOffset.dx + cx / zoomLevel;
    final worldBottom = worldOffset.dy + cy / zoomLevel;

    final startX =
        (worldLeft / gridWorldSpacing).floor() * gridWorldSpacing;
    final startY =
        (worldTop / gridWorldSpacing).floor() * gridWorldSpacing;

    for (double wx = startX; wx < worldRight; wx += gridWorldSpacing) {
      for (double wy = startY; wy < worldBottom; wy += gridWorldSpacing) {
        final sx = cx + (wx - worldOffset.dx) * zoomLevel;
        final sy = cy + (wy - worldOffset.dy) * zoomLevel;
        canvas.drawCircle(Offset(sx, sy), 1.0, paint);
      }
    }
  }

  // ── Node painting facade ───────────────────────────────────────────────────

  /// Paint a placeholder representation of [node] for the given [lod].
  ///
  /// Full widget-based rendering is handled by the widget layer; this method
  /// is used by the [CustomPainter] for quick fallback/overview rendering.
  void paintNodePlaceholder({
    required Canvas canvas,
    required CanvasNode node,
    required LodLevel lod,
    required Rect screenRect,
    bool isSelected = false,
  }) {
    final color = _colorForNode(node);
    final paint = Paint()..color = color;

    switch (lod) {
      case LodLevel.overview:
        // Filled rect only.
        canvas.drawRect(screenRect, paint);

      case LodLevel.coarse:
        // Filled rect + outline + title.
        canvas.drawRect(screenRect, paint..color = color.withOpacity(0.6));
        canvas.drawRect(
          screenRect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        _drawTitle(canvas, node, screenRect);

      case LodLevel.normal:
      case LodLevel.detailed:
        // The Widget layer handles full rendering; paint nothing here.
        break;
    }

    if (isSelected) {
      canvas.drawRect(
        screenRect.inflate(2),
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Color _colorForNode(CanvasNode node) {
    switch (node.runtimeType.toString()) {
      case 'StickyNoteNode':
        return const Color(0xFFFFF176);
      case 'TextCardNode':
        return const Color(0xFFE3F2FD);
      case 'FrameNode':
        return const Color(0xFFE8EAF6);
      case 'GroupNode':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFEEEEEE);
    }
  }

  void _drawTitle(Canvas canvas, CanvasNode node, Rect screenRect) {
    String? title;
    if (node is StrokeRegionNode) title = node.title;
    if (node is TextCardNode) {
      title = node.text.length > 20 ? node.text.substring(0, 20) : node.text;
    }
    if (node is StickyNoteNode) {
      title = node.text.length > 20 ? node.text.substring(0, 20) : node.text;
    }
    if (node is FrameNode) title = node.label;

    if (title == null || title.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF333333),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: screenRect.width - 4);

    tp.paint(
      canvas,
      screenRect.topLeft + const Offset(2, 2),
    );
  }
}
