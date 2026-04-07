import 'package:flutter/material.dart';
import 'package:biscuitse/app/theme/colors.dart';
import 'package:biscuitse/features/canvas/domain/models/canvas_config.dart';

/// Renders page background templates as the lowest canvas layer.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.config});

  final CanvasConfig config;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PageBackgroundPainter(config: config),
        size: Size(config.width, config.height),
      );
}

class _PageBackgroundPainter extends CustomPainter {
  _PageBackgroundPainter({required this.config});

  final CanvasConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Base fill ────────────────────────────────────────────────────────────
    final bgColor = config.template == PageTemplate.chalkboard
        ? AppColors.chalkboardGreen
        : AppColors.canvasWarm;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    switch (config.template) {
      case PageTemplate.blank:
        break;
      case PageTemplate.lined:
        _drawLines(canvas, size);
      case PageTemplate.grid:
        _drawGrid(canvas, size);
      case PageTemplate.dotted:
        _drawDots(canvas, size);
      case PageTemplate.chalkboard:
        _drawChalkboardLines(canvas, size);
    }

    // ── Left margin ──────────────────────────────────────────────────────────
    if (config.showMargin && config.template != PageTemplate.chalkboard) {
      _drawMargin(canvas, size);
    }
  }

  void _drawLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasLine.withOpacity(0.6)
      ..strokeWidth = 0.5;

    double y = config.lineSpacing * 2;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += config.lineSpacing;
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasGrid.withOpacity(0.4)
      ..strokeWidth = 0.5;

    double x = 0;
    while (x <= size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += config.gridSpacing;
    }

    double y = 0;
    while (y <= size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += config.gridSpacing;
    }
  }

  void _drawDots(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasDot.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double y = config.dotSpacing;
    while (y < size.height) {
      double x = config.dotSpacing;
      while (x < size.width) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
        x += config.dotSpacing;
      }
      y += config.dotSpacing;
    }
  }

  void _drawChalkboardLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.7;

    double y = config.lineSpacing * 2;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += config.lineSpacing;
    }
  }

  void _drawMargin(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB3BA).withOpacity(0.5)
      ..strokeWidth = 0.7;
    canvas.drawLine(
      const Offset(72, 0),
      Offset(72, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PageBackgroundPainter old) =>
      old.config != config;
}
