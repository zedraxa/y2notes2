import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/stickers/data/stamp_paths.dart';
import 'package:y2notes2/features/stickers/data/washi_patterns.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';
import 'package:y2notes2/features/stickers/domain/models/washi_pattern.dart';
import 'package:y2notes2/features/stickers/data/sticker_packs.dart';

class StickerRenderer {
  void renderSticker(
    Canvas canvas,
    StickerElement sticker, {
    bool isSelected = false,
  }) {
    canvas.save();
    canvas.translate(sticker.position.dx, sticker.position.dy);
    canvas.rotate(sticker.rotation);
    canvas.scale(sticker.scale);

    switch (sticker.type) {
      case StickerType.emoji:
      case StickerType.image:
        _renderEmoji(canvas, sticker);
      case StickerType.stamp:
        _renderStamp(canvas, sticker, sticker.opacity);
      case StickerType.washi:
        _renderWashi(canvas, sticker);
    }

    if (isSelected) {
      _renderSelectionHandles(canvas, sticker);
    }

    if (sticker.isLocked) {
      _renderLockIndicator(canvas, sticker);
    }

    canvas.restore();
  }

  void _renderEmoji(Canvas canvas, StickerElement sticker) {
    const fontSize = 48.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: sticker.assetKey,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black.withOpacity(sticker.opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  void _renderStamp(Canvas canvas, StickerElement sticker, double opacity) {
    final path = StampPaths.get(sticker.assetKey);
    final fillPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.deepPurple.shade800.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _renderWashi(Canvas canvas, StickerElement sticker) {
    final length = sticker.washiLength ?? 200.0;
    final width = sticker.washiWidth ?? 40.0;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: length,
      height: width,
    );

    final patterns = StickerPacks.washiPatterns;
    final pattern = patterns.firstWhere(
      (p) => p.id == sticker.assetKey,
      orElse: () => patterns.first,
    );

    final tintedPattern = WashiPattern(
      id: pattern.id,
      name: pattern.name,
      patternType: pattern.patternType,
      color: sticker.washiTint ?? pattern.color,
      secondaryColor: pattern.secondaryColor,
      opacity: pattern.opacity * sticker.opacity,
    );

    WashiPatternPainter.draw(canvas, rect, tintedPattern);
  }

  void _renderSelectionHandles(Canvas canvas, StickerElement sticker) {
    final bounds = _getLocalBounds(sticker);
    final dashPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawDashedRect(canvas, bounds, dashPaint);

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleStroke = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final handles = [
      Offset(bounds.left, bounds.top),
      Offset(bounds.center.dx, bounds.top),
      Offset(bounds.right, bounds.top),
      Offset(bounds.right, bounds.center.dy),
      Offset(bounds.right, bounds.bottom),
      Offset(bounds.center.dx, bounds.bottom),
      Offset(bounds.left, bounds.bottom),
      Offset(bounds.left, bounds.center.dy),
    ];

    for (final h in handles) {
      canvas.drawCircle(h, 6, handlePaint);
      canvas.drawCircle(h, 6, handleStroke);
    }

    // Rotation handle above top-center
    final rotHandle = Offset(bounds.center.dx, bounds.top - 28);
    canvas.drawCircle(rotHandle, 6, handlePaint);
    canvas.drawCircle(rotHandle, 6, handleStroke);
    canvas.drawLine(
      Offset(bounds.center.dx, bounds.top),
      rotHandle,
      dashPaint,
    );
  }

  Rect _getLocalBounds(StickerElement sticker) {
    switch (sticker.type) {
      case StickerType.emoji:
      case StickerType.image:
        const half = 28.0;
        return const Rect.fromLTRB(-half, -half, half, half);
      case StickerType.stamp:
        return const Rect.fromLTRB(-52, -52, 52, 52);
      case StickerType.washi:
        final length = sticker.washiLength ?? 200.0;
        final width = sticker.washiWidth ?? 40.0;
        return Rect.fromCenter(
          center: Offset.zero,
          width: length,
          height: width,
        );
    }
  }

  /// Draws a small padlock icon at the bottom-right corner of locked stickers.
  void _renderLockIndicator(Canvas canvas, StickerElement sticker) {
    final bounds = _getLocalBounds(sticker);
    const size = 14.0;
    final center = Offset(bounds.right - size / 2, bounds.bottom - size / 2);

    // Background circle
    canvas.drawCircle(
      center,
      size * 0.7,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Lock body (rounded rect)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + const Offset(0, 2), width: 8, height: 6),
      const Radius.circular(1),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Lock shackle (arc)
    final shacklePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: center + const Offset(0, -1), width: 6, height: 6),
      math.pi,
      math.pi,
      false,
      shacklePaint,
    );
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;

    void drawDashedLine(Offset a, Offset b) {
      final total = (b - a).distance;
      var traveled = 0.0;
      var drawing = true;
      final dir = (b - a) / total;
      while (traveled < total) {
        final segLen = drawing ? dashLen : gapLen;
        final end = (traveled + segLen).clamp(0.0, total);
        if (drawing) {
          canvas.drawLine(a + dir * traveled, a + dir * end, paint);
        }
        traveled = end;
        drawing = !drawing;
      }
    }

    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }
}
