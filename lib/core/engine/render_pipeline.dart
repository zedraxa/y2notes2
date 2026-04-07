import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:biscuitse/core/engine/stroke_renderer.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';

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
  int _cachedStrokeCount = 0;

  /// Returns the cached [ui.Image] of all committed strokes.
  ///
  /// Rebuilds the cache only when [strokes] has changed.
  Future<ui.Image?> getStrokesCache(
    List<Stroke> strokes,
    Size canvasSize,
  ) async {
    if (strokes.isEmpty) {
      _strokesCache = null;
      _cachedStrokeCount = 0;
      return null;
    }

    // Only rebuild if stroke count changed (new stroke committed / undo).
    if (strokes.length == _cachedStrokeCount && _strokesCache != null) {
      return _strokesCache;
    }

    _strokesCache = await _rasterize(strokes, canvasSize);
    _cachedStrokeCount = strokes.length;
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
    _cachedStrokeCount = 0;
  }

  void dispose() {
    _strokesCache?.dispose();
    _strokesCache = null;
  }
}
