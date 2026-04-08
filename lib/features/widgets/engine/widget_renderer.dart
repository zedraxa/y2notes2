import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

/// Renders widget placeholders on the canvas via CustomPainter.
class WidgetRenderer extends CustomPainter {
  WidgetRenderer({
    required this.widgets,
    this.selectedWidgetId,
  });

  final List<SmartWidget> widgets;
  final String? selectedWidgetId;

  @override
  void paint(Canvas canvas, Size size) {
    for (final w in widgets) {
      final isSelected = w.id == selectedWidgetId;

      // Draw a subtle placeholder rectangle.
      final rect = w.bounds;
      final bgPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSelected ? Colors.blue : Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 1;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      // Draw widget emoji & label as a quick indicator.
      final tp = TextPainter(
        text: TextSpan(
          text: '${w.iconEmoji} ${w.label}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 8);

      tp.paint(canvas, Offset(rect.left + 4, rect.top + 4));
    }
  }

  @override
  bool shouldRepaint(WidgetRenderer oldDelegate) =>
      oldDelegate.widgets != widgets ||
      oldDelegate.selectedWidgetId != selectedWidgetId;
}
