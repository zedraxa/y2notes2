import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/entities/shape_element.dart';
import '../domain/entities/shape_type.dart';

/// Renders [ShapeElement]s onto a [Canvas].
class ShapeRenderer {
  /// Render a single [shape] onto [canvas].
  void renderShape(Canvas canvas, ShapeElement shape) {
    canvas.save();

    // Apply opacity
    final opacity = shape.opacity.clamp(0.0, 1.0);
    if (opacity <= 0.0) {
      canvas.restore();
      return;
    }

    // Rotate around the shape's center.
    if (shape.rotation != 0.0) {
      canvas.translate(shape.center.dx, shape.center.dy);
      canvas.rotate(shape.rotation);
      canvas.translate(-shape.center.dx, -shape.center.dy);
    }

    final strokePaint = Paint()
      ..color = shape.strokeColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = shape.fillColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (shape.type) {
      case ShapeType.rectangle:
      case ShapeType.square:
        _drawRect(canvas, shape, strokePaint, fillPaint);
      case ShapeType.circle:
        _drawCircle(canvas, shape, strokePaint, fillPaint);
      case ShapeType.ellipse:
        _drawEllipse(canvas, shape, strokePaint, fillPaint);
      case ShapeType.line:
        _drawLine(canvas, shape, strokePaint);
      case ShapeType.arrow:
        _drawArrow(canvas, shape, strokePaint);
      case ShapeType.triangle:
      case ShapeType.diamond:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
        _drawPolygon(canvas, shape, strokePaint, fillPaint);
      case ShapeType.star:
        _drawStar(canvas, shape, strokePaint, fillPaint);
      case ShapeType.freeform:
        break;
    }

    canvas.restore();
  }

  // ─── Shape drawers ────────────────────────────────────────────────────────

  void _drawRect(Canvas canvas, ShapeElement shape, Paint stroke, Paint fill) {
    final rrect = RRect.fromRectAndRadius(
      shape.bounds,
      Radius.circular(shape.cornerRadius),
    );
    if (shape.isFilled) {
      _drawFillPattern(canvas, shape, shape.bounds);
      canvas.drawRRect(rrect, fill);
    }
    canvas.drawRRect(rrect, stroke);
  }

  void _drawCircle(
      Canvas canvas, ShapeElement shape, Paint stroke, Paint fill) {
    final c = shape.center;
    final r = math.min(shape.bounds.width, shape.bounds.height) / 2;
    if (shape.isFilled) {
      _drawFillPattern(canvas, shape, shape.bounds);
      canvas.drawCircle(c, r, fill);
    }
    canvas.drawCircle(c, r, stroke);
  }

  void _drawEllipse(
      Canvas canvas, ShapeElement shape, Paint stroke, Paint fill) {
    if (shape.isFilled) {
      _drawFillPattern(canvas, shape, shape.bounds);
      canvas.drawOval(shape.bounds, fill);
    }
    canvas.drawOval(shape.bounds, stroke);
  }

  void _drawLine(Canvas canvas, ShapeElement shape, Paint stroke) {
    canvas.drawLine(
      Offset(shape.bounds.left, shape.center.dy),
      Offset(shape.bounds.right, shape.center.dy),
      stroke,
    );
  }

  void _drawArrow(Canvas canvas, ShapeElement shape, Paint stroke) {
    final start = Offset(shape.bounds.left, shape.center.dy);
    final end = Offset(shape.bounds.right, shape.center.dy);
    canvas.drawLine(start, end, stroke);

    // Arrowhead
    final headSize = math.max(shape.strokeWidth * 4, 12.0);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final p1 = Offset(
      end.dx - headSize * math.cos(angle - math.pi / 6),
      end.dy - headSize * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      end.dx - headSize * math.cos(angle + math.pi / 6),
      end.dy - headSize * math.sin(angle + math.pi / 6),
    );
    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(
        headPath,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true);
  }

  void _drawPolygon(
      Canvas canvas, ShapeElement shape, Paint stroke, Paint fill) {
    final verts = shape.vertices.isNotEmpty
        ? shape.vertices
        : _defaultVertices(shape);
    if (verts.isEmpty) return;
    final path = Path()..moveTo(verts[0].dx, verts[0].dy);
    for (int i = 1; i < verts.length; i++) {
      path.lineTo(verts[i].dx, verts[i].dy);
    }
    path.close();
    if (shape.isFilled) {
      _drawFillPattern(canvas, shape, shape.bounds);
      canvas.drawPath(path, fill);
    }
    canvas.drawPath(path, stroke);
  }

  void _drawStar(
      Canvas canvas, ShapeElement shape, Paint stroke, Paint fill) {
    final cx = shape.center.dx;
    final cy = shape.center.dy;
    final rx = shape.bounds.width / 2;
    final ry = shape.bounds.height / 2;
    final innerRx = rx * 0.4;
    final innerRy = ry * 0.4;
    final points = 5;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + math.pi * i / points;
      final r1 = i.isEven ? rx : innerRx;
      final r2 = i.isEven ? ry : innerRy;
      final x = cx + r1 * math.cos(angle);
      final y = cy + r2 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    if (shape.isFilled) {
      _drawFillPattern(canvas, shape, shape.bounds);
      canvas.drawPath(path, fill);
    }
    canvas.drawPath(path, stroke);
  }

  // ─── Fill patterns ────────────────────────────────────────────────────────

  void _drawFillPattern(Canvas canvas, ShapeElement shape, Rect bounds) {
    if (shape.fillPattern == ShapeFillPattern.solid) return;

    final paint = Paint()
      ..color = shape.strokeColor
          .withValues(alpha: shape.opacity * 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.save();
    // Clip to shape outline
    final clipPath = _buildClipPath(shape);
    if (clipPath != null) canvas.clipPath(clipPath);

    const spacing = 8.0;
    switch (shape.fillPattern) {
      case ShapeFillPattern.hatched:
        for (double x = bounds.left - bounds.height;
            x < bounds.right + bounds.height;
            x += spacing) {
          canvas.drawLine(
              Offset(x, bounds.top), Offset(x + bounds.height, bounds.bottom), paint);
        }
      case ShapeFillPattern.crosshatch:
        for (double x = bounds.left - bounds.height;
            x < bounds.right + bounds.height;
            x += spacing) {
          canvas.drawLine(
              Offset(x, bounds.top), Offset(x + bounds.height, bounds.bottom), paint);
          canvas.drawLine(
              Offset(x + bounds.height, bounds.top), Offset(x, bounds.bottom), paint);
        }
      case ShapeFillPattern.dotted:
        final dotPaint = Paint()
          ..color = shape.strokeColor.withValues(alpha: shape.opacity * 0.4)
          ..style = PaintingStyle.fill;
        for (double x = bounds.left + spacing / 2;
            x < bounds.right;
            x += spacing) {
          for (double y = bounds.top + spacing / 2;
              y < bounds.bottom;
              y += spacing) {
            canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
          }
        }
      case ShapeFillPattern.solid:
      case ShapeFillPattern.none:
        break;
    }
    canvas.restore();
  }

  Path? _buildClipPath(ShapeElement shape) {
    switch (shape.type) {
      case ShapeType.rectangle:
      case ShapeType.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              shape.bounds, Radius.circular(shape.cornerRadius)));
      case ShapeType.circle:
        return Path()
          ..addOval(Rect.fromCircle(
              center: shape.center,
              radius: math.min(shape.bounds.width, shape.bounds.height) / 2));
      case ShapeType.ellipse:
        return Path()..addOval(shape.bounds);
      case ShapeType.triangle:
      case ShapeType.diamond:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
        final verts = shape.vertices.isNotEmpty
            ? shape.vertices
            : _defaultVertices(shape);
        if (verts.isEmpty) return null;
        final p = Path()..moveTo(verts[0].dx, verts[0].dy);
        for (int i = 1; i < verts.length; i++) {
          p.lineTo(verts[i].dx, verts[i].dy);
        }
        return p..close();
      default:
        return null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<Offset> _defaultVertices(ShapeElement shape) {
    final cx = shape.center.dx;
    final cy = shape.center.dy;
    final rx = shape.bounds.width / 2;
    final ry = shape.bounds.height / 2;

    switch (shape.type) {
      case ShapeType.triangle:
        return [
          Offset(cx, shape.bounds.top),
          Offset(shape.bounds.right, shape.bounds.bottom),
          Offset(shape.bounds.left, shape.bounds.bottom),
        ];
      case ShapeType.diamond:
        return [
          Offset(cx, shape.bounds.top),
          Offset(shape.bounds.right, cy),
          Offset(cx, shape.bounds.bottom),
          Offset(shape.bounds.left, cy),
        ];
      case ShapeType.pentagon:
        return List.generate(5, (i) {
          final angle = -math.pi / 2 + 2 * math.pi * i / 5;
          return Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
        });
      case ShapeType.hexagon:
        return List.generate(6, (i) {
          final angle = 2 * math.pi * i / 6;
          return Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
        });
      default:
        return [];
    }
  }
}
