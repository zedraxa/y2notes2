import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/entities/shape_element.dart';
import '../domain/entities/shape_type.dart';

/// Result of a hit test against a collection of shapes.
class ShapeHitResult {
  const ShapeHitResult({
    required this.shapeId,
    this.handleIndex,
  });

  /// ID of the shape that was hit.
  final String shapeId;

  /// Handle index (0-7 = resize, 8 = rotation), or null for body hit.
  final int? handleIndex;

  bool get isHandle => handleIndex != null;
  bool get isRotationHandle => handleIndex == 8;
  bool get isResizeHandle =>
      handleIndex != null && handleIndex! >= 0 && handleIndex! < 8;
}

/// Provides hit-testing for [ShapeElement]s on the canvas.
class ShapeHitTester {
  /// How many logical pixels around a handle are considered a hit.
  static const double handleHitRadius = 14.0;

  /// Test [point] against all [shapes] (last shape = topmost).
  ///
  /// Returns the first matching result, or null if nothing was hit.
  static ShapeHitResult? hitTest(
      List<ShapeElement> shapes, Offset point) {
    // Test in reverse order so the topmost shape wins.
    for (int i = shapes.length - 1; i >= 0; i--) {
      final shape = shapes[i];
      final handleIndex = _testHandles(shape, point);
      if (handleIndex != null) {
        return ShapeHitResult(shapeId: shape.id, handleIndex: handleIndex);
      }
      if (_testBody(shape, point)) {
        return ShapeHitResult(shapeId: shape.id);
      }
    }
    return null;
  }

  /// Returns handle positions for [shape] in canvas coordinates.
  ///
  /// Indices 0-7 = resize handles (clockwise from top-left):
  ///   0=TL, 1=TC, 2=TR, 3=MR, 4=BR, 5=BC, 6=BL, 7=ML
  /// Index 8 = rotation handle (above top-centre).
  static List<Offset> handlePositions(ShapeElement shape) {
    final b = shape.bounds;
    final cx = b.center.dx;
    final cy = b.center.dy;
    return [
      b.topLeft, // 0 TL
      Offset(cx, b.top), // 1 TC
      b.topRight, // 2 TR
      Offset(b.right, cy), // 3 MR
      b.bottomRight, // 4 BR
      Offset(cx, b.bottom), // 5 BC
      b.bottomLeft, // 6 BL
      Offset(b.left, cy), // 7 ML
      Offset(cx, b.top - 30.0), // 8 rotation
    ];
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static int? _testHandles(ShapeElement shape, Offset point) {
    final handles = handlePositions(shape);
    for (int i = 0; i < handles.length; i++) {
      if ((handles[i] - point).distance <= handleHitRadius) return i;
    }
    return null;
  }

  static bool _testBody(ShapeElement shape, Offset point) {
    // Inflate by half stroke width for easier selection.
    final inflated = shape.bounds.inflate(shape.strokeWidth / 2 + 4.0);
    if (!inflated.contains(point)) return false;

    switch (shape.type) {
      case ShapeType.circle:
        final r = math.min(shape.bounds.width, shape.bounds.height) / 2 +
            shape.strokeWidth;
        return (point - shape.center).distance <= r;
      case ShapeType.ellipse:
        final rx = shape.bounds.width / 2 + shape.strokeWidth;
        final ry = shape.bounds.height / 2 + shape.strokeWidth;
        if (rx <= 0 || ry <= 0) return false;
        final dx = (point.dx - shape.center.dx) / rx;
        final dy = (point.dy - shape.center.dy) / ry;
        return dx * dx + dy * dy <= 1.0;
      case ShapeType.rectangle:
      case ShapeType.square:
        return shape.bounds.inflate(shape.strokeWidth).contains(point);
      default:
        final verts = shape.vertices;
        if (verts.length >= 3) return _pointInPolygon(point, verts);
        return shape.bounds.inflate(shape.strokeWidth).contains(point);
    }
  }

  /// Ray-casting point-in-polygon test.
  static bool _pointInPolygon(Offset point, List<Offset> polygon) {
    int crossings = 0;
    final n = polygon.length;
    for (int i = 0; i < n; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % n];
      if (((a.dy <= point.dy && point.dy < b.dy) ||
              (b.dy <= point.dy && point.dy < a.dy)) &&
          point.dx < (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        crossings++;
      }
    }
    return crossings.isOdd;
  }
}
