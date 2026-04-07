import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/entities/canvas_edge.dart';
import '../domain/entities/canvas_node.dart';

/// Renders [CanvasEdge]s using Flutter's [Canvas] API.
///
/// Call [paint] during a [CustomPainter.paint] pass, passing the world→screen
/// transform so that all coordinates are converted correctly.
class EdgeRenderer {
  const EdgeRenderer();

  // ── Public entry point ────────────────────────────────────────────────────

  /// Paint all [edges] onto [canvas].
  ///
  /// [nodeMap] is used to resolve source/target node positions.
  /// [worldToScreen] converts world coordinates to screen coordinates.
  /// [selectedEdgeId] highlights the selected edge.
  /// [zoomLevel] controls label font scaling.
  void paint({
    required Canvas canvas,
    required List<CanvasEdge> edges,
    required Map<String, CanvasNode> nodeMap,
    required Offset Function(Offset) worldToScreen,
    String? selectedEdgeId,
    double zoomLevel = 1.0,
  }) {
    for (final edge in edges) {
      final source = nodeMap[edge.sourceNodeId];
      final target = nodeMap[edge.targetNodeId];
      if (source == null || target == null) continue;

      final isSelected = edge.id == selectedEdgeId;
      _paintEdge(
        canvas: canvas,
        edge: edge,
        source: source,
        target: target,
        worldToScreen: worldToScreen,
        isSelected: isSelected,
        zoomLevel: zoomLevel,
      );
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  void _paintEdge({
    required Canvas canvas,
    required CanvasEdge edge,
    required CanvasNode source,
    required CanvasNode target,
    required Offset Function(Offset) worldToScreen,
    required bool isSelected,
    required double zoomLevel,
  }) {
    final srcAnchor = _resolveAnchor(source, target, edge.sourceAnchor);
    final tgtAnchor = _resolveAnchor(target, source, edge.targetAnchor);

    final p1 = worldToScreen(srcAnchor);
    final p2 = worldToScreen(tgtAnchor);

    final paint = Paint()
      ..color = isSelected
          ? Color.lerp(edge.color, Colors.blue, 0.5)!
          : edge.color
      ..strokeWidth = (edge.width * zoomLevel).clamp(1.0, 20.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (edge.style == EdgeStyle.dashed) {
      _applyDash(paint);
    }

    // Build path.
    final path = _buildPath(edge, p1, p2, worldToScreen);

    // Selection halo.
    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.blue.withOpacity(0.25)
          ..strokeWidth = paint.strokeWidth + 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dotted pattern via dash.
    if (edge.style == EdgeStyle.dotted) {
      _drawDotted(canvas, path, paint);
    } else if (edge.style == EdgeStyle.dashed) {
      _drawDashed(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Arrow heads.
    if (edge.sourceArrow != null && edge.sourceArrow != ArrowStyle.none) {
      final tangent = _startTangent(path);
      _drawArrowHead(canvas, p1, tangent, edge.sourceArrow!, edge.color, paint.strokeWidth);
    }
    if (edge.targetArrow != null && edge.targetArrow != ArrowStyle.none) {
      final tangent = _endTangent(path);
      _drawArrowHead(canvas, p2, tangent, edge.targetArrow!, edge.color, paint.strokeWidth);
    }

    // Label at midpoint.
    if (edge.label != null && edge.label!.isNotEmpty) {
      _drawLabel(
        canvas: canvas,
        path: path,
        label: edge.label!,
        color: edge.color,
        zoomLevel: zoomLevel,
      );
    }
  }

  Path _buildPath(
    CanvasEdge edge,
    Offset p1,
    Offset p2,
    Offset Function(Offset) w2s,
  ) {
    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    switch (edge.pathType) {
      case EdgePathType.straight:
        path.lineTo(p2.dx, p2.dy);

      case EdgePathType.curved:
      case EdgePathType.bezier:
        final cp1 = edge.controlPoint1 != null
            ? w2s(edge.controlPoint1!)
            : _defaultCp1(p1, p2);
        final cp2 = edge.controlPoint2 != null
            ? w2s(edge.controlPoint2!)
            : _defaultCp2(p1, p2);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);

      case EdgePathType.orthogonal:
        final mx = (p1.dx + p2.dx) / 2;
        path.lineTo(mx, p1.dy);
        path.lineTo(mx, p2.dy);
        path.lineTo(p2.dx, p2.dy);
    }

    return path;
  }

  Offset _defaultCp1(Offset p1, Offset p2) {
    final dx = (p2.dx - p1.dx).abs() * 0.5;
    return Offset(p1.dx + dx, p1.dy);
  }

  Offset _defaultCp2(Offset p1, Offset p2) {
    final dx = (p2.dx - p1.dx).abs() * 0.5;
    return Offset(p2.dx - dx, p2.dy);
  }

  Offset _resolveAnchor(CanvasNode node, CanvasNode other, AnchorPoint anchor) {
    final b = node.worldBounds;
    if (anchor == AnchorPoint.auto) {
      // Pick the side closest to the other node's centre.
      final delta = other.worldPosition - node.worldPosition;
      if (delta.dx.abs() > delta.dy.abs()) {
        return delta.dx > 0
            ? Offset(b.right, b.center.dy)
            : Offset(b.left, b.center.dy);
      } else {
        return delta.dy > 0
            ? Offset(b.center.dx, b.bottom)
            : Offset(b.center.dx, b.top);
      }
    }
    switch (anchor) {
      case AnchorPoint.top:
        return Offset(b.center.dx, b.top);
      case AnchorPoint.bottom:
        return Offset(b.center.dx, b.bottom);
      case AnchorPoint.left:
        return Offset(b.left, b.center.dy);
      case AnchorPoint.right:
        return Offset(b.right, b.center.dy);
      case AnchorPoint.center:
        return b.center;
      case AnchorPoint.auto:
        return b.center;
    }
  }

  // Arrow head rendering.
  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset tangent,
    ArrowStyle style,
    Color color,
    double strokeWidth,
  ) {
    final size = strokeWidth * 4 + 6;
    final angle = math.atan2(tangent.dy, tangent.dx);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (style) {
      case ArrowStyle.arrow:
      case ArrowStyle.filledArrow:
        final left = tip -
            Offset(
              math.cos(angle - 0.5) * size,
              math.sin(angle - 0.5) * size,
            );
        final right = tip -
            Offset(
              math.cos(angle + 0.5) * size,
              math.sin(angle + 0.5) * size,
            );
        final path = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
        if (style == ArrowStyle.arrow) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = strokeWidth;
        }
        canvas.drawPath(path, paint);

      case ArrowStyle.circle:
      case ArrowStyle.filledCircle:
        if (style == ArrowStyle.circle) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = strokeWidth;
        }
        canvas.drawCircle(tip, size / 2, paint);

      case ArrowStyle.diamond:
      case ArrowStyle.filledDiamond:
        final top = Offset(
          tip.dx - math.cos(angle) * size,
          tip.dy - math.sin(angle) * size,
        );
        final l = Offset(
          tip.dx + math.cos(angle + math.pi / 2) * size / 2,
          tip.dy + math.sin(angle + math.pi / 2) * size / 2,
        );
        final r = Offset(
          tip.dx + math.cos(angle - math.pi / 2) * size / 2,
          tip.dy + math.sin(angle - math.pi / 2) * size / 2,
        );
        final far = Offset(
          top.dx - math.cos(angle) * size,
          top.dy - math.sin(angle) * size,
        );
        final path = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(l.dx, l.dy)
          ..lineTo(far.dx, far.dy)
          ..lineTo(r.dx, r.dy)
          ..close();
        if (style == ArrowStyle.diamond) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = strokeWidth;
        }
        canvas.drawPath(path, paint);

      case ArrowStyle.none:
        break;
    }
  }

  // Tangent at start of path (for source arrow).
  Offset _startTangent(Path path) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return const Offset(1, 0);
    final m = metrics.first;
    final t0 = m.getTangentForOffset(0);
    final t1 = m.getTangentForOffset(math.min(1.0, m.length));
    if (t0 == null || t1 == null) return const Offset(1, 0);
    // Reverse so it points away from the path.
    final v = t1.vector - t0.vector;
    return v == Offset.zero ? const Offset(1, 0) : -v / v.distance;
  }

  // Tangent at end of path (for target arrow).
  Offset _endTangent(Path path) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return const Offset(1, 0);
    final m = metrics.last;
    final t = m.getTangentForOffset(m.length);
    if (t == null) return const Offset(1, 0);
    return t.vector;
  }

  // Label at path midpoint.
  void _drawLabel({
    required Canvas canvas,
    required Path path,
    required String label,
    required Color color,
    required double zoomLevel,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final mid = m.getTangentForOffset(m.length / 2);
    if (mid == null) return;

    final fontSize = (12 * zoomLevel).clamp(8.0, 18.0);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          backgroundColor: Colors.white.withOpacity(0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      mid.position - Offset(tp.width / 2, tp.height / 2),
    );
  }

  // Dashed / dotted drawing helpers.
  void _applyDash(Paint p) {
    // Flutter's Paint doesn't support dash natively; we handle it manually.
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    _drawPatternPath(canvas, path, paint, dashLen: 12, gapLen: 6);
  }

  void _drawDotted(Canvas canvas, Path path, Paint paint) {
    _drawPatternPath(canvas, path, paint, dashLen: 2, gapLen: 5);
  }

  void _drawPatternPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLen,
    required double gapLen,
  }) {
    for (final m in path.computeMetrics()) {
      double dist = 0;
      bool drawing = true;
      while (dist < m.length) {
        final len = drawing ? dashLen : gapLen;
        final end = (dist + len).clamp(0, m.length).toDouble();
        if (drawing) {
          canvas.drawPath(m.extractPath(dist, end), paint);
        }
        dist = end;
        drawing = !drawing;
      }
    }
  }
}
