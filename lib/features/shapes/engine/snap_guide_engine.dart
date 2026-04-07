import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../domain/entities/shape_element.dart';

/// A visible alignment guide line for snap feedback.
class SnapGuide extends Equatable {
  const SnapGuide({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  List<Object?> get props => [start, end];
}

/// Computes snap guides and snapped positions when moving/resizing shapes.
class SnapGuideEngine {
  /// Snap distance threshold in logical pixels.
  static const double snapThreshold = 8.0;

  /// Grid cell size (used when grid snap is enabled).
  static const double gridSize = 20.0;

  /// Compute snap guides and the adjusted [candidate] offset when moving a
  /// shape near [other] shapes.
  ///
  /// Returns the (possibly snapped) offset and a list of active guide lines.
  static ({Offset offset, List<SnapGuide> guides}) snapToShapes({
    required Offset candidate,
    required Size shapeSize,
    required List<ShapeElement> others,
  }) {
    var snapped = candidate;
    final guides = <SnapGuide>[];

    final candidateRect = candidate & shapeSize;
    final cx = candidateRect.center.dx;
    final cy = candidateRect.center.dy;
    final right = candidateRect.right;
    final bottom = candidateRect.bottom;

    for (final other in others) {
      final ob = other.bounds;

      // ── Horizontal snaps ───────────────────────────────────────────────
      for (final targetX in [ob.left, ob.center.dx, ob.right]) {
        // Left edge
        if ((candidateRect.left - targetX).abs() < snapThreshold) {
          snapped = Offset(targetX, snapped.dy);
          guides.add(SnapGuide(
              start: Offset(targetX, ob.top - 20),
              end: Offset(targetX, ob.bottom + 20)));
        }
        // Right edge
        if ((right - targetX).abs() < snapThreshold) {
          snapped = Offset(targetX - shapeSize.width, snapped.dy);
          guides.add(SnapGuide(
              start: Offset(targetX, ob.top - 20),
              end: Offset(targetX, ob.bottom + 20)));
        }
        // Centre X
        if ((cx - targetX).abs() < snapThreshold) {
          snapped = Offset(targetX - shapeSize.width / 2, snapped.dy);
          guides.add(SnapGuide(
              start: Offset(targetX, ob.top - 20),
              end: Offset(targetX, ob.bottom + 20)));
        }
      }

      // ── Vertical snaps ─────────────────────────────────────────────────
      for (final targetY in [ob.top, ob.center.dy, ob.bottom]) {
        // Top edge
        if ((candidateRect.top - targetY).abs() < snapThreshold) {
          snapped = Offset(snapped.dx, targetY);
          guides.add(SnapGuide(
              start: Offset(ob.left - 20, targetY),
              end: Offset(ob.right + 20, targetY)));
        }
        // Bottom edge
        if ((bottom - targetY).abs() < snapThreshold) {
          snapped = Offset(snapped.dx, targetY - shapeSize.height);
          guides.add(SnapGuide(
              start: Offset(ob.left - 20, targetY),
              end: Offset(ob.right + 20, targetY)));
        }
        // Centre Y
        if ((cy - targetY).abs() < snapThreshold) {
          snapped = Offset(snapped.dx, targetY - shapeSize.height / 2);
          guides.add(SnapGuide(
              start: Offset(ob.left - 20, targetY),
              end: Offset(ob.right + 20, targetY)));
        }
      }
    }

    return (offset: snapped, guides: guides);
  }

  /// Snap [point] to the nearest grid intersection.
  static Offset snapToGrid(Offset point) {
    return Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );
  }
}
