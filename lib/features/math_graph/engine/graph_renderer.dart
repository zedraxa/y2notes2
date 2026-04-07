import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../domain/entities/graph_element.dart';
import '../domain/entities/graph_function.dart';
import '../domain/models/graph_type.dart';

/// Renders a [GraphElement] (axes, grid, function curves) onto a [Canvas].
class GraphRenderer {
  const GraphRenderer();

  /// Render the full graph within [element.bounds].
  void render(Canvas canvas, GraphElement element) {
    canvas.save();
    canvas.clipRect(element.bounds);

    // Background
    canvas.drawRect(
      element.bounds,
      Paint()..color = element.backgroundColor,
    );

    if (element.showGrid) _drawGrid(canvas, element);
    if (element.showAxes) _drawAxes(canvas, element);
    if (element.showLabels) _drawLabels(canvas, element);

    // Plot each visible function.
    for (final func in element.functions) {
      if (func.isVisible && func.plotPoints.isNotEmpty) {
        _drawFunction(canvas, element, func);
      }
    }

    // Title
    if (element.title != null && element.title!.isNotEmpty) {
      _drawTitle(canvas, element);
    }

    canvas.restore();
  }

  // ─── Grid ───────────────────────────────────────────────────────────────

  void _drawGrid(Canvas canvas, GraphElement g) {
    final paint = Paint()
      ..color = g.gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final xStep = _niceStep(g.xRange);
    final yStep = _niceStep(g.yRange);

    // Vertical grid lines
    var x = (g.xMin / xStep).floorToDouble() * xStep;
    while (x <= g.xMax) {
      final sx = _mapX(x, g);
      canvas.drawLine(
        Offset(sx, g.bounds.top),
        Offset(sx, g.bounds.bottom),
        paint,
      );
      x += xStep;
    }

    // Horizontal grid lines
    var y = (g.yMin / yStep).floorToDouble() * yStep;
    while (y <= g.yMax) {
      final sy = _mapY(y, g);
      canvas.drawLine(
        Offset(g.bounds.left, sy),
        Offset(g.bounds.right, sy),
        paint,
      );
      y += yStep;
    }
  }

  // ─── Axes ───────────────────────────────────────────────────────────────

  void _drawAxes(Canvas canvas, GraphElement g) {
    final paint = Paint()
      ..color = g.axisColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // X axis (y = 0)
    if (g.yMin <= 0 && g.yMax >= 0) {
      final sy = _mapY(0, g);
      canvas.drawLine(
        Offset(g.bounds.left, sy),
        Offset(g.bounds.right, sy),
        paint,
      );
    }

    // Y axis (x = 0)
    if (g.xMin <= 0 && g.xMax >= 0) {
      final sx = _mapX(0, g);
      canvas.drawLine(
        Offset(sx, g.bounds.top),
        Offset(sx, g.bounds.bottom),
        paint,
      );
    }
  }

  // ─── Labels ─────────────────────────────────────────────────────────────

  void _drawLabels(Canvas canvas, GraphElement g) {
    final xStep = _niceStep(g.xRange);
    final yStep = _niceStep(g.yRange);

    final textStyle = TextStyle(
      color: g.axisColor.withValues(alpha: 0.7),
      fontSize: 10,
    );

    // X axis labels
    var x = (g.xMin / xStep).ceilToDouble() * xStep;
    while (x <= g.xMax) {
      if (x.abs() > xStep * 0.01) {
        // skip 0
        final sx = _mapX(x, g);
        final yBase = g.yMin <= 0 && g.yMax >= 0
            ? _mapY(0, g)
            : g.bounds.bottom;
        _drawText(
          canvas,
          _formatNumber(x),
          Offset(sx, yBase + 2),
          textStyle,
          alignment: Alignment.topCenter,
        );
      }
      x += xStep;
    }

    // Y axis labels
    var y = (g.yMin / yStep).ceilToDouble() * yStep;
    while (y <= g.yMax) {
      if (y.abs() > yStep * 0.01) {
        final sy = _mapY(y, g);
        final xBase = g.xMin <= 0 && g.xMax >= 0
            ? _mapX(0, g)
            : g.bounds.left;
        _drawText(
          canvas,
          _formatNumber(y),
          Offset(xBase - 4, sy),
          textStyle,
          alignment: Alignment.centerRight,
        );
      }
      y += yStep;
    }
  }

  // ─── Function curves ────────────────────────────────────────────────────

  void _drawFunction(Canvas canvas, GraphElement g, GraphFunction func) {
    final paint = Paint()
      ..color = func.style.color
      ..strokeWidth = func.style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final points = func.plotPoints;

    if (func.type == GraphType.scatter || func.type == GraphType.implicit) {
      _drawPoints(canvas, g, func, paint);
      return;
    }

    // Draw as a connected path, breaking on large gaps (discontinuities).
    final path = Path();
    var moved = false;

    for (var i = 0; i < points.length; i++) {
      final (px, py) = points[i];
      final sx = _mapX(px, g);
      final sy = _mapY(py, g);

      // Detect discontinuity (large vertical jump).
      if (i > 0) {
        final (_, prevY) = points[i - 1];
        if ((py - prevY).abs() > g.yRange * 0.5) {
          moved = false;
        }
      }

      if (!moved) {
        path.moveTo(sx, sy);
        moved = true;
      } else {
        path.lineTo(sx, sy);
      }
    }

    if (func.style.isDashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    if (func.style.showPoints) {
      _drawPoints(canvas, g, func, paint);
    }
  }

  void _drawPoints(
      Canvas canvas, GraphElement g, GraphFunction func, Paint paint) {
    final dotPaint = Paint()
      ..color = func.style.color
      ..style = PaintingStyle.fill;

    for (final (px, py) in func.plotPoints) {
      final sx = _mapX(px, g);
      final sy = _mapY(py, g);
      if (sx >= g.bounds.left &&
          sx <= g.bounds.right &&
          sy >= g.bounds.top &&
          sy <= g.bounds.bottom) {
        canvas.drawCircle(Offset(sx, sy), func.style.pointRadius, dotPaint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 6, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += 12; // 6px dash + 6px gap
      }
    }
  }

  // ─── Title ──────────────────────────────────────────────────────────────

  void _drawTitle(Canvas canvas, GraphElement g) {
    _drawText(
      canvas,
      g.title!,
      Offset(g.bounds.center.dx, g.bounds.top + 8),
      TextStyle(
        color: g.axisColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      alignment: Alignment.topCenter,
    );
  }

  // ─── Coordinate mapping ─────────────────────────────────────────────────

  /// Map a graph-space X value to screen-space X.
  double _mapX(double x, GraphElement g) {
    return g.bounds.left +
        (x - g.xMin) / (g.xMax - g.xMin) * g.bounds.width;
  }

  /// Map a graph-space Y value to screen-space Y (inverted: higher Y → lower pixel).
  double _mapY(double y, GraphElement g) {
    return g.bounds.bottom -
        (y - g.yMin) / (g.yMax - g.yMin) * g.bounds.height;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Choose a "nice" grid step for the given range.
  double _niceStep(double range) {
    final rough = range / 8; // aim for ~8 grid lines
    final exp = (math.log(rough) / math.ln10).floorToDouble();
    final frac = rough / math.pow(10, exp);
    double nice;
    if (frac < 1.5) {
      nice = 1;
    } else if (frac < 3) {
      nice = 2;
    } else if (frac < 7) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * math.pow(10, exp);
  }

  String _formatNumber(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    Alignment alignment = Alignment.topLeft,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: style.fontSize,
    ))
      ..pushStyle(style.getTextStyle())
      ..addText(text);

    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 100));

    final dx = position.dx - paragraph.width * (alignment.x + 1) / 2;
    final dy = position.dy - paragraph.height * (alignment.y + 1) / 2;

    canvas.drawParagraph(paragraph, Offset(dx, dy));
  }
}
