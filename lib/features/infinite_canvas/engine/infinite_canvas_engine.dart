import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'quad_tree.dart';
import '../domain/entities/canvas_node.dart';

/// Core viewport and coordinate-transformation engine for the infinite canvas.
///
/// World-space uses (0, 0) as the canvas origin. Positive X is right,
/// positive Y is down — matching Flutter's screen coordinate convention.
class InfiniteCanvasEngine {
  InfiniteCanvasEngine({
    this.worldOffset = Offset.zero,
    this.zoomLevel = 1.0,
    this.screenSize = Size.zero,
  }) : spatialIndex = QuadTree<CanvasNode>(
          bounds: const Rect.fromLTWH(-50000, -50000, 100000, 100000),
        );

  // ── Constants ─────────────────────────────────────────────────────────────

  /// Minimum zoom (1 %) — shows a massive overview.
  static const double minZoom = 0.01;

  /// Maximum zoom (5 000 %) — pixel-level detail.
  static const double maxZoom = 50.0;

  // ── Viewport state ────────────────────────────────────────────────────────

  /// Current pan position in world coordinates (world point at screen centre).
  Offset worldOffset;

  /// Current zoom level; 1.0 = 100 %.
  double zoomLevel;

  /// Physical size of the canvas widget in screen pixels.
  Size screenSize;

  // ── Spatial index ─────────────────────────────────────────────────────────

  /// QuadTree for O(log n) visibility queries.
  QuadTree<CanvasNode> spatialIndex;

  // ── Coordinate transforms ──────────────────────────────────────────────────

  /// Convert a screen-space point to world coordinates.
  Offset screenToWorld(Offset screenPoint) {
    final cx = screenSize.width / 2;
    final cy = screenSize.height / 2;
    return Offset(
      worldOffset.dx + (screenPoint.dx - cx) / zoomLevel,
      worldOffset.dy + (screenPoint.dy - cy) / zoomLevel,
    );
  }

  /// Convert a world-space point to screen coordinates.
  Offset worldToScreen(Offset worldPoint) {
    final cx = screenSize.width / 2;
    final cy = screenSize.height / 2;
    return Offset(
      cx + (worldPoint.dx - worldOffset.dx) * zoomLevel,
      cy + (worldPoint.dy - worldOffset.dy) * zoomLevel,
    );
  }

  /// The rectangle of world space that is currently visible on screen.
  Rect get visibleWorldRect {
    final topLeft = screenToWorld(Offset.zero);
    final bottomRight = screenToWorld(
      Offset(screenSize.width, screenSize.height),
    );
    return Rect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      bottomRight.dx,
      bottomRight.dy,
    );
  }

  // ── Pan & Zoom helpers ─────────────────────────────────────────────────────

  /// Pan the viewport by [delta] in screen pixels.
  void pan(Offset delta) {
    worldOffset -= delta / zoomLevel;
  }

  /// Zoom by [factor] keeping [focalScreenPoint] fixed on screen.
  void zoomBy(double factor, {Offset? focalScreenPoint}) {
    final focal = focalScreenPoint ??
        Offset(screenSize.width / 2, screenSize.height / 2);
    final worldFocal = screenToWorld(focal);
    zoomLevel = (zoomLevel * factor).clamp(minZoom, maxZoom);
    // Adjust worldOffset so the focal point stays under the pointer.
    final cx = screenSize.width / 2;
    final cy = screenSize.height / 2;
    worldOffset = Offset(
      worldFocal.dx - (focal.dx - cx) / zoomLevel,
      worldFocal.dy - (focal.dy - cy) / zoomLevel,
    );
  }

  /// Set zoom to [level] keeping the screen centre fixed.
  void setZoom(double level) {
    zoomLevel = level.clamp(minZoom, maxZoom);
  }

  // ── Spatial index helpers ──────────────────────────────────────────────────

  /// Rebuild the entire spatial index from [nodes].
  void rebuildIndex(Iterable<CanvasNode> nodes) {
    spatialIndex = QuadTree<CanvasNode>(
      bounds: const Rect.fromLTWH(-50000, -50000, 100000, 100000),
    );
    for (final node in nodes) {
      spatialIndex.insert(node, node.worldBounds);
    }
  }

  /// Insert or update a single node in the spatial index.
  void upsertNode(CanvasNode node) {
    spatialIndex.remove(node.id);
    spatialIndex.insert(node, node.worldBounds);
  }

  /// Remove a node from the spatial index.
  void removeNode(String nodeId) => spatialIndex.remove(nodeId);

  /// Return all nodes whose bounds intersect the current visible rect.
  List<CanvasNode> queryVisible() =>
      spatialIndex.query(visibleWorldRect);

  // ── Fit-to-content ─────────────────────────────────────────────────────────

  /// Compute zoom and offset to fit all [nodeBounds] within the screen,
  /// with optional [padding] in world units.
  void fitToContent(
    List<Rect> nodeBounds, {
    double padding = 100.0,
  }) {
    if (nodeBounds.isEmpty || screenSize == Size.zero) return;

    double minX = nodeBounds.first.left;
    double minY = nodeBounds.first.top;
    double maxX = nodeBounds.first.right;
    double maxY = nodeBounds.first.bottom;

    for (final r in nodeBounds) {
      minX = math.min(minX, r.left);
      minY = math.min(minY, r.top);
      maxX = math.max(maxX, r.right);
      maxY = math.max(maxY, r.bottom);
    }

    final worldW = (maxX - minX) + padding * 2;
    final worldH = (maxY - minY) + padding * 2;

    final scaleX = screenSize.width / worldW;
    final scaleY = screenSize.height / worldH;
    zoomLevel = math.min(scaleX, scaleY).clamp(minZoom, maxZoom);
    worldOffset = Offset(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
    );
  }
}
