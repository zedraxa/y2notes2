import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/shape_type.dart';

/// Grid picker for selecting a shape type before drawing.
class ShapeTypePicker extends StatelessWidget {
  const ShapeTypePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ShapeType? selected;
  final ValueChanged<ShapeType> onSelected;

  static const _types = [
    ShapeType.rectangle,
    ShapeType.square,
    ShapeType.circle,
    ShapeType.ellipse,
    ShapeType.triangle,
    ShapeType.line,
    ShapeType.arrow,
    ShapeType.star,
    ShapeType.diamond,
    ShapeType.pentagon,
    ShapeType.hexagon,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _types.length,
        itemBuilder: (context, i) {
          final type = _types[i];
          final isSelected = type == selected;
          return GestureDetector(
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(28, 28),
                    painter: _ShapeIconPainter(
                      type: type,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label(type),
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _label(ShapeType t) {
    switch (t) {
      case ShapeType.rectangle:
        return 'Rectangle';
      case ShapeType.square:
        return 'Square';
      case ShapeType.circle:
        return 'Circle';
      case ShapeType.ellipse:
        return 'Ellipse';
      case ShapeType.triangle:
        return 'Triangle';
      case ShapeType.line:
        return 'Line';
      case ShapeType.arrow:
        return 'Arrow';
      case ShapeType.star:
        return 'Star';
      case ShapeType.diamond:
        return 'Diamond';
      case ShapeType.pentagon:
        return 'Pentagon';
      case ShapeType.hexagon:
        return 'Hexagon';
      case ShapeType.freeform:
        return 'Free';
    }
  }
}

/// Paints a small preview of a shape type.
class _ShapeIconPainter extends CustomPainter {
  const _ShapeIconPainter({required this.type, required this.color});

  final ShapeType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.4;
    final ry = size.height * 0.4;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);

    switch (type) {
      case ShapeType.rectangle:
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(cx, cy),
                width: rx * 2,
                height: ry * 1.4),
            paint);
      case ShapeType.square:
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(cx, cy), width: rx * 1.8, height: rx * 1.8),
            paint);
      case ShapeType.circle:
        canvas.drawCircle(Offset(cx, cy), rx, paint);
      case ShapeType.ellipse:
        canvas.drawOval(rect, paint);
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(cx, cy - ry)
          ..lineTo(cx + rx, cy + ry)
          ..lineTo(cx - rx, cy + ry)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.line:
        canvas.drawLine(
            Offset(cx - rx, cy), Offset(cx + rx, cy), paint);
      case ShapeType.arrow:
        canvas.drawLine(
            Offset(cx - rx, cy), Offset(cx + rx, cy), paint);
        final h = rx * 0.4;
        canvas.drawLine(
            Offset(cx + rx, cy), Offset(cx + rx - h, cy - h), paint);
        canvas.drawLine(
            Offset(cx + rx, cy), Offset(cx + rx - h, cy + h), paint);
      case ShapeType.star:
        _drawStar(canvas, cx, cy, rx, ry, paint);
      case ShapeType.diamond:
        final path = Path()
          ..moveTo(cx, cy - ry)
          ..lineTo(cx + rx, cy)
          ..lineTo(cx, cy + ry)
          ..lineTo(cx - rx, cy)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.pentagon:
        _drawPolygon(canvas, cx, cy, rx, ry, 5, paint);
      case ShapeType.hexagon:
        _drawPolygon(canvas, cx, cy, rx, ry, 6, paint);
      case ShapeType.freeform:
        canvas.drawCircle(Offset(cx, cy), rx * 0.6, paint);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double rx, double ry,
      Paint paint) {
    final path = Path();
    final innerRx = rx * 0.4;
    final innerRy = ry * 0.4;
    const points = 5;
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
    canvas.drawPath(path, paint);
  }

  void _drawPolygon(Canvas canvas, double cx, double cy, double rx, double ry,
      int n, Paint paint) {
    final path = Path();
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final x = cx + rx * math.cos(angle);
      final y = cy + ry * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShapeIconPainter old) =>
      old.type != type || old.color != color;
}
