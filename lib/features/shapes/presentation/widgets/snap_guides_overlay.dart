import 'package:flutter/material.dart';
import '../../engine/snap_guide_engine.dart';

/// Overlay that paints active snap guide lines.
class SnapGuidesOverlay extends StatelessWidget {
  const SnapGuidesOverlay({super.key, required this.guides});

  final List<SnapGuide> guides;

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _SnapGuidePainter(guides: guides),
        size: Size.infinite,
      ),
    );
  }
}

class _SnapGuidePainter extends CustomPainter {
  const _SnapGuidePainter({required this.guides});

  final List<SnapGuide> guides;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      canvas.drawLine(guide.start, guide.end, paint);
    }
  }

  @override
  bool shouldRepaint(_SnapGuidePainter old) => old.guides != guides;
}
