import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:biscuits/core/engine/stroke_renderer.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';

/// Orchestrates the two-layer rendering pipeline:
///  - Committed strokes → rasterized bitmap cache via [PictureRecorder]
///  - Active stroke → live vector rendering on [CustomPainter]
///
/// Using a bitmap cache for all completed strokes and only re-recording
/// when strokes change gives 60fps even with thousands of strokes.
class RenderPipeline {
  RenderPipeline({required this.renderer});

  final StrokeRenderer renderer;

  ui.Image? _strokesCache;
  int _cachedContentHash = 0;

  /// Returns the cached [ui.Image] of all committed strokes.
  ///
  /// Rebuilds the cache only when the content hash of [strokes] has changed,
  /// correctly handling undo/redo scenarios where stroke count stays the same
  /// but the actual strokes differ.
  Future<ui.Image?> getStrokesCache(
    List<Stroke> strokes,
    Size canvasSize,
  ) async {
    if (strokes.isEmpty) {
      _strokesCache = null;
      _cachedContentHash = 0;
      return null;
    }

    // Use a content-based hash that accounts for stroke identity (not just count).
    final contentHash = Object.hashAll(strokes.map((s) => s.id));
    if (contentHash == _cachedContentHash && _strokesCache != null) {
      return _strokesCache;
    }

    _strokesCache = await _rasterize(strokes, canvasSize);
    _cachedContentHash = contentHash;
    return _strokesCache;
  }

  Future<ui.Image> _rasterize(List<Stroke> strokes, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    for (final stroke in strokes) {
      renderer.renderStroke(canvas, stroke);
    }

    final picture = recorder.endRecording();
    return picture.toImage(size.width.round(), size.height.round());
  }

  /// Invalidate the cache (e.g. after undo/redo).
  void invalidateCache() {
    _strokesCache = null;
    _cachedContentHash = 0;
  }

  void dispose() {
    _strokesCache?.dispose();
    _strokesCache = null;
  }
}
