import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';

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
        _drawLines(canvas, size, config.lineSpacing);
      case PageTemplate.narrowRuled:
        // Narrow ruled: fixed ~21 px (≈ 8 mm at 96 dpi) spacing.
        _drawLines(canvas, size, 21.0);
      case PageTemplate.wideRuled:
        // Wide ruled: fixed ~42 px (≈ 11 mm) spacing.
        _drawLines(canvas, size, 42.0);
      case PageTemplate.grid:
        _drawGrid(canvas, size);
      case PageTemplate.dotted:
        _drawDots(canvas, size);
      case PageTemplate.chalkboard:
        _drawChalkboardLines(canvas, size);
      case PageTemplate.isometric:
        _drawIsometric(canvas, size);
      case PageTemplate.musicStaff:
        _drawMusicStaff(canvas, size);
      case PageTemplate.hexagonal:
        _drawHexagonal(canvas, size);
      case PageTemplate.calligraphy:
        _drawCalligraphy(canvas, size);
    }

    // ── Left margin ──────────────────────────────────────────────────────────
    if (config.showMargin &&
        config.template != PageTemplate.chalkboard &&
        config.template != PageTemplate.isometric &&
        config.template != PageTemplate.hexagonal) {
      _drawMargin(canvas, size);
    }
  }

  void _drawLines(Canvas canvas, Size size, double spacing) {
    final paint = Paint()
      ..color = AppColors.canvasLine.withOpacity(0.6)
      ..strokeWidth = 0.5;

    double y = spacing * 2;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += spacing;
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

  /// Isometric dot grid: three sets of parallel lines at 0°, 60°, and 120°.
  void _drawIsometric(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasDot.withOpacity(0.55)
      ..strokeWidth = 0.5;

    const spacing = 28.0;
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);

    // Horizontal lines
    double y = 0;
    while (y <= size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += spacing;
    }

    // 60° lines (down-right)
    final dy = spacing / math.sin(math.pi / 3);
    double start = -diagonal;
    while (start < size.width + diagonal) {
      canvas.drawLine(
        Offset(start, 0),
        Offset(start + size.height / math.tan(math.pi / 3), size.height),
        paint,
      );
      start += dy;
    }

    // 120° lines (down-left)
    start = -diagonal;
    while (start < size.width + diagonal) {
      canvas.drawLine(
        Offset(start, 0),
        Offset(start - size.height / math.tan(math.pi / 3), size.height),
        paint,
      );
      start += dy;
    }
  }

  /// Five-line music staff repeated with regular staff gap.
  void _drawMusicStaff(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.canvasLine.withOpacity(0.65)
      ..strokeWidth = 0.7;
    final barPaint = Paint()
      ..color = AppColors.canvasLine.withOpacity(0.25)
      ..strokeWidth = 0.5;

    const lineGap = 8.0;   // gap between the 5 lines in a staff
    const staffGap = 36.0; // gap between consecutive staves

    double topY = staffGap;
    while (topY + lineGap * 4 < size.height) {
      // Draw the 5 staff lines.
      for (int i = 0; i < 5; i++) {
        final y = topY + i * lineGap;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
      // Draw a faint ledger space separator between staves.
      final midY = topY + lineGap * 4 + staffGap / 2;
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), barPaint);

      topY += lineGap * 4 + staffGap;
    }
  }

  /// Hexagonal grid drawn with flat-top hexagons.
  void _drawHexagonal(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasGrid.withOpacity(0.4)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const r = 20.0; // circumradius
    final w = math.sqrt(3) * r; // hex width (flat-top)
    final h = 2 * r;            // hex height
    final hStep = h * 0.75;     // vertical step between rows

    int row = 0;
    double cy = r;
    while (cy - r < size.height) {
      final offset = (row % 2 == 0) ? 0.0 : w / 2;
      double cx = offset + w / 2;
      while (cx - w / 2 < size.width) {
        _drawHex(canvas, paint, cx, cy, r);
        cx += w;
      }
      cy += hStep;
      row++;
    }
  }

  void _drawHex(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Calligraphy guide: base, ascender, descender, and slant lines.
  void _drawCalligraphy(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = AppColors.canvasLine.withOpacity(0.7)
      ..strokeWidth = 0.7;
    final guidePaint = Paint()
      ..color = AppColors.canvasLine.withOpacity(0.35)
      ..strokeWidth = 0.5;
    final slantPaint = Paint()
      ..color = const Color(0xFFFFB3BA).withOpacity(0.25)
      ..strokeWidth = 0.5;

    const bodyHeight = 24.0;     // x-height
    const ascender = 16.0;       // above x-height
    const descender = 12.0;      // below baseline
    const setHeight = bodyHeight + ascender + descender + 16.0; // full set

    double baseY = ascender + 32.0;
    while (baseY < size.height) {
      // Baseline
      canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), basePaint);
      // x-height line
      canvas.drawLine(
        Offset(0, baseY - bodyHeight),
        Offset(size.width, baseY - bodyHeight),
        guidePaint,
      );
      // Ascender line
      canvas.drawLine(
        Offset(0, baseY - bodyHeight - ascender),
        Offset(size.width, baseY - bodyHeight - ascender),
        guidePaint,
      );
      // Descender line
      canvas.drawLine(
        Offset(0, baseY + descender),
        Offset(size.width, baseY + descender),
        guidePaint,
      );
      baseY += setHeight;
    }

    // Slant lines at ~55° (italic slant)
    const slantSpacing = 24.0;
    final slantTan = math.tan(55 * math.pi / 180);
    double startX = -size.height / slantTan;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + size.height / slantTan, size.height),
        slantPaint,
      );
      startX += slantSpacing;
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
