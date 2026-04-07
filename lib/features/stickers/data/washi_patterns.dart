import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/stickers/domain/models/washi_pattern.dart';

/// Provides Canvas drawing utilities for washi tape patterns.
class WashiPatternPainter {
  const WashiPatternPainter._();

  /// Draw a washi tape pattern onto [canvas] within the given [rect].
  static void draw(
    Canvas canvas,
    Rect rect,
    WashiPattern pattern,
  ) {
    final paint = Paint()
      ..color = pattern.color.withOpacity(pattern.opacity)
      ..style = PaintingStyle.fill;

    // Base fill
    canvas.drawRect(rect, paint);

    switch (pattern.patternType) {
      case WashiPatternType.striped:
        _drawStripes(canvas, rect, pattern);
      case WashiPatternType.dotted:
        _drawDots(canvas, rect, pattern);
      case WashiPatternType.solid:
        // Already drawn base
        break;
    }

    // Subtle edge highlight for washi tape look
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, 2), edgePaint);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - 2, rect.width, 2), edgePaint);
  }

  static void _drawStripes(Canvas canvas, Rect rect, WashiPattern pattern) {
    if (pattern.secondaryColor == null) return;
    final stripePaint = Paint()
      ..color = pattern.secondaryColor!.withOpacity(pattern.opacity * 0.5)
      ..style = PaintingStyle.fill;
    const stripeWidth = 12.0;
    const gap = 8.0;
    var x = rect.left;
    canvas.save();
    canvas.clipRect(rect);
    while (x < rect.right + rect.height) {
      final stripeRect = Rect.fromLTWH(x, rect.top - 2, stripeWidth, rect.height + 4);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-math.pi / 6);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRect(stripeRect, stripePaint);
      canvas.restore();
      x += stripeWidth + gap;
    }
    canvas.restore();
  }

  static void _drawDots(Canvas canvas, Rect rect, WashiPattern pattern) {
    if (pattern.secondaryColor == null) return;
    final dotPaint = Paint()
      ..color = pattern.secondaryColor!.withOpacity(pattern.opacity * 0.7)
      ..style = PaintingStyle.fill;
    const dotR = 3.0;
    const spacing = 14.0;
    canvas.save();
    canvas.clipRect(rect);
    var row = 0;
    var y = rect.top + spacing / 2;
    while (y < rect.bottom) {
      var x = rect.left + (row.isOdd ? spacing / 2 : spacing / 4);
      while (x < rect.right) {
        canvas.drawCircle(Offset(x, y), dotR, dotPaint);
        x += spacing;
      }
      y += spacing * 0.7;
      row++;
    }
    canvas.restore();
  }
}
