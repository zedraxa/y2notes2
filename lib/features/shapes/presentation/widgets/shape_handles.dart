import 'package:flutter/material.dart';
import '../../domain/entities/shape_element.dart';
import '../../engine/shape_hit_tester.dart';

/// Overlays 8 resize handles + 1 rotation handle on the selected shape.
///
/// The parent [GestureDetector] in [ShapeOverlay] is responsible for
/// dispatching drag events; this widget only handles the visual rendering.
class ShapeHandles extends StatelessWidget {
  const ShapeHandles({
    super.key,
    required this.shape,
    this.onDeleteTap,
  });

  final ShapeElement shape;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final handles = ShapeHitTester.handlePositions(shape);

    return Stack(
      children: [
        // Dashed bounding box
        Positioned.fromRect(
          rect: shape.bounds.inflate(2),
          child: IgnorePointer(
            child: CustomPaint(painter: _DashedBorderPainter()),
          ),
        ),

        // Resize handles (indices 0-7)
        for (int i = 0; i < 8; i++)
          _HandleDot(position: handles[i], color: Colors.blue),

        // Rotation handle (index 8)
        _HandleDot(
          position: handles[8],
          color: Colors.orange,
          icon: Icons.rotate_right,
        ),

        // Delete button
        Positioned(
          left: shape.bounds.right + 6,
          top: shape.bounds.top - 6,
          child: GestureDetector(
            onTap: onDeleteTap,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _HandleDot extends StatelessWidget {
  const _HandleDot({
    required this.position,
    required this.color,
    this.icon,
  });

  final Offset position;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const size = 12.0;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 3,
            ),
          ],
        ),
        child: icon != null
            ? Icon(icon, size: 8, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Paints a dashed rectangle border.
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashLen = 5.0;
    const gapLen = 3.0;
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    void drawDashedLine(Offset from, Offset to) {
      final dir = to - from;
      final len = dir.distance;
      if (len == 0) return;
      final unit = dir / len;
      double d = 0.0;
      bool drawing = true;
      while (d < len) {
        final segEnd = (d + (drawing ? dashLen : gapLen)).clamp(0.0, len);
        if (drawing) {
          canvas.drawLine(from + unit * d, from + unit * segEnd, paint);
        }
        d = segEnd;
        drawing = !drawing;
      }
    }

    drawDashedLine(Offset.zero, Offset(size.width, 0));
    drawDashedLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawDashedLine(
        Offset(size.width, size.height), Offset(0, size.height));
    drawDashedLine(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}
