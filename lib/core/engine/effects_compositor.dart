import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/stroke_renderer.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effects_engine.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_element.dart';
import 'package:y2notes2/features/shapes/engine/shape_renderer.dart';

/// Composites all rendering layers in the correct order.
///
/// Implemented layers:
///  1. Page background template (drawn by PageBackgroundPainter)
///  2. Committed strokes bitmap cache (or live stroke list if cache is absent)
///  3. Writing effects on completed strokes
///  4. Placed shapes (ShapeElement list)
///  5. Active stroke (live vector, drawn on top of shapes)
///  6. Interaction effects (touch ripple, snap glow, selection pulse, etc.)
///
/// Future layers:
///  7. UI overlay (selection handles — rendered as Flutter widgets above)
class EffectsCompositor {
  EffectsCompositor({
    required this.strokeRenderer,
    required this.effectsEngine,
    this.interactionEngine,
  }) : _shapeRenderer = ShapeRenderer();

  final StrokeRenderer strokeRenderer;
  final WritingEffectsEngine effectsEngine;

  /// Optional interaction engine; when set, Layer 6 is rendered.
  final InteractionEffectsEngine? interactionEngine;

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

    // ── Layer 6: Interaction effects (above shapes & active stroke) ──────────
    interactionEngine?.render(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size, CanvasConfig config) {
    // Delegate to PageBackground logic — drawn via CustomPainter below.
    // Actual template drawing is in PageBackgroundPainter widget.
  }
}
