import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/stroke_renderer.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';

/// Composites all rendering layers in the correct order.
///
/// Layer order:
///  1. Page background template
///  2. Committed strokes bitmap cache
///  3. Writing effects on completed strokes
///  4. Active stroke (live vector)
///  5. Active writing effects (trail particles, pressure bloom)
///  6. Interaction effects (stub)
///  7. UI overlay (selection handles — stub)
class EffectsCompositor {
  EffectsCompositor({
    required this.strokeRenderer,
    required this.effectsEngine,
  });

  final StrokeRenderer strokeRenderer;
  final WritingEffectsEngine effectsEngine;

  /// Render everything onto [canvas] given current [size].
  void compose({
    required Canvas canvas,
    required Size size,
    required CanvasConfig config,
    required List<Stroke> strokes,
    required Stroke? activeStroke,
    ui.Image? strokesCache,
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

    // ── Layer 4: Active (live) stroke ────────────────────────────────────────
    if (activeStroke != null) {
      strokeRenderer.renderStroke(canvas, activeStroke);
    }

    // Layers 5-7 are handled by the effects engine and future PRs.
  }

  void _drawBackground(Canvas canvas, Size size, CanvasConfig config) {
    // Delegate to PageBackground logic — drawn via CustomPainter below.
    // Actual template drawing is in PageBackgroundPainter widget.
  }
}
