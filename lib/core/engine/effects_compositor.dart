import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:biscuitse/core/engine/stroke_renderer.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:biscuitse/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuitse/features/effects/interaction/interaction_effects_engine.dart';
import 'package:biscuitse/features/effects/writing/writing_effects_engine.dart';
import 'package:biscuitse/features/handwriting/domain/entities/text_block.dart';
import 'package:biscuitse/features/shapes/domain/entities/shape_element.dart';
import 'package:biscuitse/features/shapes/engine/shape_renderer.dart';
import 'package:biscuitse/features/stickers/domain/entities/sticker_element.dart';
import 'package:biscuitse/features/stickers/engine/sticker_renderer.dart';

/// Composites all rendering layers in the correct order.
///
/// Implemented layers:
///  1. Page background template (drawn by PageBackgroundPainter)
///  2. Committed strokes bitmap cache (or live stroke list if cache is absent)
///  3. Writing effects on completed strokes
///  4. Placed shapes (ShapeElement list)
///  5. Active stroke (live vector, drawn on top of shapes)
///  6. Stickers & stamps
///  7. Text blocks (converted handwriting)
///  8. Interaction effects (touch ripple, snap glow, selection pulse, etc.)
///
/// Note: Remote cursors (collaboration layer) are rendered as Flutter widgets
/// above the canvas, not through this compositor.
///
/// Future layers:
///  9. UI overlay (selection handles — rendered as Flutter widgets above)
class EffectsCompositor {
  EffectsCompositor({
    required this.strokeRenderer,
    required this.effectsEngine,
    this.interactionEngine,
    StickerRenderer? stickerRenderer,
  })  : _shapeRenderer = ShapeRenderer(),
        _stickerRenderer = stickerRenderer ?? StickerRenderer();

  final StrokeRenderer strokeRenderer;
  final WritingEffectsEngine effectsEngine;

  /// Optional interaction engine; when set, Layer 8 is rendered.
  final InteractionEffectsEngine? interactionEngine;

  final ShapeRenderer _shapeRenderer;
  final StickerRenderer _stickerRenderer;

  void compose({
    required Canvas canvas,
    required Size size,
    required CanvasConfig config,
    required List<Stroke> strokes,
    required Stroke? activeStroke,
    ui.Image? strokesCache,
    ToolSettings? activeToolSettings,
    List<ShapeElement> shapes = const [],
    List<StickerElement> stickers = const [],
    String? selectedStickerId,
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

    // ── Layer 4: Shapes ─────────────────────────────────────────────────────
    for (final shape in shapes) {
      _shapeRenderer.renderShape(canvas, shape);
    }

    // ── Layer 5: Active (live) stroke ────────────────────────────────────────
    if (activeStroke != null) {
      strokeRenderer.renderStroke(canvas, activeStroke, activeToolSettings);
    }

    // ── Layer 6: Stickers & stamps ──────────────────────────────────────────
    final sorted = [...stickers]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final sticker in sorted) {
      _stickerRenderer.renderSticker(
        canvas,
        sticker,
        isSelected: sticker.id == selectedStickerId,
      );
    }

    // ── Layer 7: Text blocks (recognized handwriting) ────────────────────────
    _drawTextBlocks(canvas, textBlocks);

    // ── Layer 8: Interaction effects (above all content) ─────────────────────
    interactionEngine?.render(canvas, size);
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
