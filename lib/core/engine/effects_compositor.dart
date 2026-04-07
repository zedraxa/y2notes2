import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/stroke_renderer.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_element.dart';
import 'package:y2notes2/features/shapes/engine/shape_renderer.dart';

/// Composites all rendering layers in the correct order.
///
/// Layer order:
///  1. Page background template
///  2. Committed strokes bitmap cache
///  3. Writing effects on completed strokes
///  4. **Shape layer** (placed shapes)
///  5. Active stroke (live vector)
///  6. Active writing effects (trail particles, pressure bloom)
///  7. Interaction effects (stub)
///  8. UI overlay (selection handles — stub)
class EffectsCompositor {
  EffectsCompositor({
    required this.strokeRenderer,
    required this.effectsEngine,
  }) : _shapeRenderer = ShapeRenderer();

  final StrokeRenderer strokeRenderer;
  final WritingEffectsEngine effectsEngine;
  final ShapeRenderer _shapeRenderer;

  /// Render everything onto [canvas] given current [size].
  void compose({
    required Canvas canvas,
    required Size size,
    required CanvasConfig config,
    required List<Stroke> strokes,
    required Stroke? activeStroke,
    ui.Image? strokesCache,
    ToolSettings? activeToolSettings,
    List<ShapeElement> shapes = const [],
  }) {
    // ── Layer 1: Background ─────────────────────────────────────────────────
    _drawBackground(canvas, size, config);

    // ── Layer 2: Committed strokes (from bitmap cache if available) ─────────
    if (strokesCache != null) {
      canvas.drawImage(strokesCache, Offset.zero, Paint());
    } else {
      for (final stroke in strokes) {
        strokeRenderer.renderStroke(canvas, stroke);
      }
    }

    // ── Layer 3: Effects on completed strokes ───────────────────────────────
    effectsEngine.render(canvas, size);

    // ── Layer 4: Shapes ─────────────────────────────────────────────────────
    for (final shape in shapes) {
      _shapeRenderer.renderShape(canvas, shape);
    }

    // ── Layer 5: Active (live) stroke ────────────────────────────────────────
    if (activeStroke != null) {
      strokeRenderer.renderStroke(canvas, activeStroke, activeToolSettings);
    }

    // Layers 6-8 are handled by the effects engine and future PRs.
  }

  void _drawBackground(Canvas canvas, Size size, CanvasConfig config) {
    // Delegate to PageBackground logic — drawn via CustomPainter below.
    // Actual template drawing is in PageBackgroundPainter widget.
  }
}
