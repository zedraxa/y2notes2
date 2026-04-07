import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../bloc/infinite_canvas_bloc.dart';
import '../../bloc/infinite_canvas_event.dart';

/// Renders a [GroupNode] — a dashed bounding box around grouped nodes.
class GroupWidget extends StatelessWidget {
  const GroupWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.scale,
  });

  final GroupNode node;
  final bool isSelected;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<InfiniteCanvasBloc>().add(SelectNode(node.id)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: _DashedBorderPainter(
              color: isSelected
                  ? Colors.blue
                  : (node.groupColor ?? Colors.grey.shade400),
              strokeWidth: isSelected ? 2.0 : 1.5,
            ),
          ),
          if (node.groupLabel != null && node.groupLabel!.isNotEmpty)
            Positioned(
              top: -(18 * scale),
              left: 4 * scale,
              child: Text(
                node.groupLabel!,
                style: TextStyle(
                  fontSize: (11 * scale).clamp(8, 16),
                  color: node.groupColor ?? Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const dashLen = 8.0;
    const gapLen = 4.0;

    for (final m in path.computeMetrics()) {
      double dist = 0;
      bool drawing = true;
      while (dist < m.length) {
        final len = drawing ? dashLen : gapLen;
        final end = (dist + len).clamp(0, m.length).toDouble();
        if (drawing) {
          canvas.drawPath(m.extractPath(dist, end), paint);
        }
        dist = end;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
