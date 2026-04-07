import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/stroke_renderer.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
import 'package:y2notes2/features/handwriting/domain/entities/text_block.dart';

/// Composites all rendering layers in the correct order.
///
/// Layer order:
///  1. Page background template
///  2. Committed strokes bitmap cache
///  3. Writing effects on completed strokes
///  4. Active stroke (live vector)
///  5. Active writing effects (trail particles, pressure bloom)
///  6. Text blocks (converted handwriting)
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
    ToolSettings? activeToolSettings,
    List<TextBlock> textBlocks = const [],
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
      strokeRenderer.renderStroke(canvas, activeStroke, activeToolSettings);
    }

    // ── Layer 5: Text blocks (recognized handwriting) ────────────────────────
    _drawTextBlocks(canvas, textBlocks);

    // Layer 6: Interaction effects / selection handles handled by future PRs.
  }

  void _drawBackground(Canvas canvas, Size size, CanvasConfig config) {
    // Delegate to PageBackground logic — drawn via CustomPainter below.
    // Actual template drawing is in PageBackgroundPainter widget.
  }

  void _drawTextBlocks(Canvas canvas, List<TextBlock> textBlocks) {
    for (final block in textBlocks) {
      if (block.text.isEmpty) continue;

      canvas.save();
      canvas.translate(block.position.dx, block.position.dy);
      if (block.rotation != 0) {
        canvas.rotate(block.rotation);
      }

      // Draw background if set
      if (block.backgroundColor != Colors.transparent) {
        final bgPaint = Paint()
          ..color = block.backgroundColor.withOpacity(block.opacity);
        // Approximate height from font size
        final approxHeight =
            ((block.style.fontSize ?? 16) * 1.4).clamp(20.0, 200.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, block.width, approxHeight),
            const Radius.circular(4),
          ),
          bgPaint,
        );
      }

      // Paint text using a ParagraphBuilder
      final style = block.style;
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: block.align,
          fontSize: style.fontSize ?? 16,
          fontWeight: style.fontWeight ?? FontWeight.normal,
          fontStyle: style.fontStyle ?? FontStyle.normal,
          maxLines: null,
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: (style.color ?? Colors.black).withOpacity(block.opacity),
          fontSize: style.fontSize ?? 16,
          fontWeight: style.fontWeight,
          fontStyle: style.fontStyle,
        ))
        ..addText(block.text);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: block.width));

      canvas.drawParagraph(paragraph, Offset.zero);
      canvas.restore();
    }
  }
}
