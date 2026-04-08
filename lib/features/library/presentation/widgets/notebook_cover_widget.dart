import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';

/// Renders a stylised notebook cover thumbnail.
///
/// Accepts a [color] and [material] and draws:
///   - A base colored rectangle with a spine on the left.
///   - A subtle material texture overlay (grain, weave, etc.) controlled
///     by [material].
///   - An optional decorative [pattern] on the cover.
///   - An optional [emblem] icon on the cover.
///   - An optional [title] drawn over the cover.
class NotebookCoverWidget extends StatelessWidget {
  const NotebookCoverWidget({
    super.key,
    required this.color,
    this.material = CoverMaterial.matte,
    this.pattern = CoverPattern.none,
    this.emblem = CoverEmblem.none,
    this.title,
    this.width = 120,
    this.height = 160,
  });

  final Color color;
  final CoverMaterial material;
  final CoverPattern pattern;
  final CoverEmblem emblem;
  final String? title;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CoverPainter(
          color: color,
          material: material,
          pattern: pattern,
          emblem: emblem,
        ),
        child: title != null ? _TitleOverlay(title: title!) : null,
      ),
    );
  }
}

// ── Cover painter ─────────────────────────────────────────────────────────────

class _CoverPainter extends CustomPainter {
  _CoverPainter({
    required this.color,
    required this.material,
    required this.pattern,
    required this.emblem,
  });

  final Color color;
  final CoverMaterial material;
  final CoverPattern pattern;
  final CoverEmblem emblem;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Shadow ────────────────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(2, 2), const Radius.circular(4)),
      shadowPaint,
    );

    // ── Base fill ─────────────────────────────────────────────────────────────
    final basePaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      basePaint,
    );

    // ── Material texture overlay ───────────────────────────────────────────────
    _paintTexture(canvas, size);

    // ── Decorative pattern ────────────────────────────────────────────────────
    if (pattern != CoverPattern.none) {
      _paintPattern(canvas, size);
    }

    // ── Emblem ────────────────────────────────────────────────────────────────
    if (emblem != CoverEmblem.none) {
      _paintEmblem(canvas, size);
    }

    // ── Spine ─────────────────────────────────────────────────────────────────
    _paintSpine(canvas, size);

    // ── Highlight edge ─────────────────────────────────────────────────────────
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(0.5),
        const Radius.circular(3.5),
      ),
      edgePaint,
    );
  }

  void _paintSpine(Canvas canvas, Size size) {
    const spineWidth = 10.0;
    final spinePaint = Paint()
      ..color = HSLColor.fromColor(color)
          .withLightness(
            (HSLColor.fromColor(color).lightness - 0.12).clamp(0.0, 1.0),
          )
          .toColor();
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        spineWidth,
        size.height,
        topLeft: const Radius.circular(4),
        bottomLeft: const Radius.circular(4),
      ),
      spinePaint,
    );

    // Spine highlight
    final spineHighlight = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      const Offset(spineWidth, 0),
      Offset(spineWidth, size.height),
      spineHighlight,
    );
  }

  void _paintTexture(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
    );

    switch (material) {
      case CoverMaterial.matte:
        _paintMatte(canvas, size);
      case CoverMaterial.leather:
        _paintLeather(canvas, size);
      case CoverMaterial.canvas:
        _paintCanvas(canvas, size);
      case CoverMaterial.linen:
        _paintLinen(canvas, size);
      case CoverMaterial.kraft:
        _paintKraft(canvas, size);
      case CoverMaterial.glossy:
        _paintGlossy(canvas, size);
    }

    canvas.restore();
  }

  /// Subtle noise grain for matte.
  void _paintMatte(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(42);
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  /// Crosshatch grain lines for leather.
  void _paintLeather(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 0.5;

    const spacing = 6.0;
    double x = 10.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += spacing;
    }
    double y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(10, y), Offset(size.width, y), paint);
      y += spacing;
    }

    // Diagonal highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8;
    double d = -size.height;
    while (d < size.width) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), highlightPaint);
      d += 18.0;
    }
  }

  /// Woven grid for canvas.
  void _paintCanvas(Canvas canvas, Size size) {
    final warpPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.2;
    final weftPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1.2;

    const spacing = 5.0;
    double x = 10.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), warpPaint);
      x += spacing;
    }
    double y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(10, y), Offset(size.width, y), weftPaint);
      y += spacing;
    }
  }

  /// Fine horizontal weave for linen.
  void _paintLinen(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.7;

    const spacing = 3.0;
    double y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(10, y), Offset(size.width, y), paint);
      y += spacing;
    }
  }

  /// Irregular fibrous texture for kraft.
  void _paintKraft(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(7);
    for (int i = 0; i < 60; i++) {
      final x1 = rng.nextDouble() * size.width;
      final y1 = rng.nextDouble() * size.height;
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x1 + rng.nextDouble() * 8 - 4, y1 + rng.nextDouble() * 3 - 1.5),
        paint,
      );
    }

    // Paper grain
    final grainPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.4;
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + rng.nextDouble() * 4 - 2, size.height),
        grainPaint,
      );
    }
  }

  /// Mirror-like specular highlight for glossy.
  void _paintGlossy(Canvas canvas, Size size) {
    final highlightRect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.04,
      size.width * 0.6,
      size.height * 0.18,
    );
    final glossPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
      glossPaint,
    );
  }

  @override
  bool shouldRepaint(_CoverPainter old) =>
      old.color != color ||
      old.material != material ||
      old.pattern != pattern ||
      old.emblem != emblem;

  // ── Pattern rendering ─────────────────────────────────────────────────────

  void _paintPattern(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
    );

    switch (pattern) {
      case CoverPattern.none:
        break;
      case CoverPattern.stripes:
        _paintStripes(canvas, size);
      case CoverPattern.dots:
        _paintDots(canvas, size);
      case CoverPattern.chevron:
        _paintChevron(canvas, size);
      case CoverPattern.diamond:
        _paintDiamond(canvas, size);
      case CoverPattern.plaid:
        _paintPlaid(canvas, size);
      case CoverPattern.moroccan:
        _paintMoroccan(canvas, size);
      case CoverPattern.herringbone:
        _paintHerringbone(canvas, size);
    }

    canvas.restore();
  }

  void _paintStripes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 2.0;
    const spacing = 8.0;
    double y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(10, y), Offset(size.width, y), paint);
      y += spacing;
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.12);
    const spacing = 10.0;
    final radius = size.width * 0.012;
    double y = spacing / 2;
    bool offset = false;
    while (y < size.height) {
      double x = 12 + (offset ? spacing / 2 : 0);
      while (x < size.width) {
        canvas.drawCircle(Offset(x, y), radius.clamp(0.8, 2.0), paint);
        x += spacing;
      }
      y += spacing;
      offset = !offset;
    }
  }

  void _paintChevron(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const rowH = 12.0;
    const halfW = 14.0;
    final path = Path();
    double y = 0.0;
    while (y < size.height + rowH) {
      path.reset();
      double x = 10.0;
      while (x < size.width + halfW) {
        path.moveTo(x, y);
        path.lineTo(x + halfW, y - rowH / 2);
        path.lineTo(x + halfW * 2, y);
        x += halfW * 2;
      }
      canvas.drawPath(path, paint);
      y += rowH;
    }
  }

  void _paintDiamond(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    const sizeD = 14.0;
    final path = Path();
    double y = -sizeD;
    bool offset = false;
    while (y < size.height + sizeD) {
      double x = 10.0 + (offset ? sizeD / 2 : 0);
      while (x < size.width + sizeD) {
        path.reset();
        path.moveTo(x, y - sizeD / 2);
        path.lineTo(x + sizeD / 2, y);
        path.lineTo(x, y + sizeD / 2);
        path.lineTo(x - sizeD / 2, y);
        path.close();
        canvas.drawPath(path, paint);
        x += sizeD;
      }
      y += sizeD;
      offset = !offset;
    }
  }

  void _paintPlaid(Canvas canvas, Size size) {
    final vPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 2.5;
    final hPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 2.5;
    const spacing = 12.0;
    double x = 10.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), vPaint);
      x += spacing;
    }
    double y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(10, y), Offset(size.width, y), hPaint);
      y += spacing;
    }
  }

  void _paintMoroccan(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    const r = 7.0;
    const spacingX = r * 2;
    const spacingY = r * 2;
    double y = 0.0;
    bool offset = false;
    while (y < size.height + r) {
      double x = 12.0 + (offset ? r : 0);
      while (x < size.width + r) {
        // Four-petal / quatrefoil approximation
        canvas.drawCircle(Offset(x, y - r * 0.35), r * 0.55, paint);
        canvas.drawCircle(Offset(x, y + r * 0.35), r * 0.55, paint);
        canvas.drawCircle(Offset(x - r * 0.35, y), r * 0.55, paint);
        canvas.drawCircle(Offset(x + r * 0.35, y), r * 0.55, paint);
        x += spacingX;
      }
      y += spacingY;
      offset = !offset;
    }
  }

  void _paintHerringbone(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;
    const brickW = 10.0;
    const brickH = 4.0;
    double y = 0.0;
    int row = 0;
    while (y < size.height) {
      double x = 10.0;
      while (x < size.width) {
        if (row.isEven) {
          canvas.drawLine(Offset(x, y), Offset(x + brickW, y + brickH), paint);
        } else {
          canvas.drawLine(Offset(x, y + brickH), Offset(x + brickW, y), paint);
        }
        x += brickW;
      }
      y += brickH;
      row++;
    }
  }

  // ── Emblem rendering ──────────────────────────────────────────────────────

  void _paintEmblem(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
    );

    // Emblem is centered horizontally, placed in the upper-middle region.
    final cx = size.width * 0.55;
    final cy = size.height * 0.38;
    final emblemSize = math.min(size.width, size.height) * 0.22;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (emblem) {
      case CoverEmblem.none:
        break;
      case CoverEmblem.star:
        _drawStar(canvas, cx, cy, emblemSize, paint);
      case CoverEmblem.heart:
        _drawHeart(canvas, cx, cy, emblemSize, paint);
      case CoverEmblem.leaf:
        _drawLeaf(canvas, cx, cy, emblemSize, paint);
      case CoverEmblem.crown:
        _drawCrown(canvas, cx, cy, emblemSize, paint);
      case CoverEmblem.compass:
        _drawCompass(canvas, cx, cy, emblemSize, paint);
      case CoverEmblem.feather:
        _drawFeather(canvas, cx, cy, emblemSize, paint);
      case CoverEmblem.moon:
        _drawMoon(canvas, cx, cy, emblemSize, paint);
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + (2 * math.pi * i / 5);
      final innerAngle = outerAngle + math.pi / 5;
      final ox = cx + s * math.cos(outerAngle);
      final oy = cy + s * math.sin(outerAngle);
      final ix = cx + s * 0.4 * math.cos(innerAngle);
      final iy = cy + s * 0.4 * math.sin(innerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final path = Path();
    path.moveTo(cx, cy + s * 0.7);
    path.cubicTo(
      cx - s * 1.2, cy - s * 0.2,
      cx - s * 0.4, cy - s * 1.0,
      cx, cy - s * 0.4,
    );
    path.cubicTo(
      cx + s * 0.4, cy - s * 1.0,
      cx + s * 1.2, cy - s * 0.2,
      cx, cy + s * 0.7,
    );
    canvas.drawPath(path, paint);
  }

  void _drawLeaf(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final path = Path();
    path.moveTo(cx, cy - s);
    path.quadraticBezierTo(cx + s * 0.9, cy - s * 0.3, cx, cy + s);
    path.quadraticBezierTo(cx - s * 0.9, cy - s * 0.3, cx, cy - s);
    canvas.drawPath(path, paint);
    // Midrib
    canvas.drawLine(Offset(cx, cy - s * 0.8), Offset(cx, cy + s * 0.8), paint);
  }

  void _drawCrown(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final path = Path();
    final left = cx - s;
    final right = cx + s;
    final top = cy - s * 0.6;
    final bottom = cy + s * 0.5;
    path.moveTo(left, bottom);
    path.lineTo(left, top + s * 0.2);
    path.lineTo(cx - s * 0.5, top + s * 0.6);
    path.lineTo(cx, top);
    path.lineTo(cx + s * 0.5, top + s * 0.6);
    path.lineTo(right, top + s * 0.2);
    path.lineTo(right, bottom);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCompass(Canvas canvas, double cx, double cy, double s, Paint paint) {
    // Outer circle
    canvas.drawCircle(Offset(cx, cy), s, paint);
    // Cardinal points
    final arrowLen = s * 0.85;
    canvas.drawLine(Offset(cx, cy - arrowLen), Offset(cx, cy + arrowLen), paint);
    canvas.drawLine(Offset(cx - arrowLen, cy), Offset(cx + arrowLen, cy), paint);
    // North arrow head
    final headSize = s * 0.25;
    canvas.drawLine(
      Offset(cx, cy - arrowLen),
      Offset(cx - headSize, cy - arrowLen + headSize),
      paint,
    );
    canvas.drawLine(
      Offset(cx, cy - arrowLen),
      Offset(cx + headSize, cy - arrowLen + headSize),
      paint,
    );
  }

  void _drawFeather(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final path = Path();
    // Quill shape
    path.moveTo(cx + s * 0.5, cy + s);
    path.quadraticBezierTo(cx - s * 0.6, cy + s * 0.1, cx - s * 0.1, cy - s);
    path.quadraticBezierTo(cx + s * 0.4, cy - s * 0.3, cx + s * 0.5, cy + s);
    canvas.drawPath(path, paint);
    // Quill spine
    canvas.drawLine(
      Offset(cx + s * 0.5, cy + s),
      Offset(cx - s * 0.05, cy - s * 0.85),
      paint,
    );
  }

  void _drawMoon(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final path = Path();
    // Outer crescent arc
    for (int i = 0; i <= 20; i++) {
      final angle = -math.pi / 2 + math.pi * i / 20;
      final x = cx + s * math.cos(angle);
      final y = cy + s * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    // Inner crescent arc (smaller, offset to the right)
    for (int i = 20; i >= 0; i--) {
      final angle = -math.pi / 2 + math.pi * i / 20;
      final x = cx + s * 0.35 + s * 0.65 * math.cos(angle);
      final y = cy + s * 0.65 * math.sin(angle);
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

// ── Title overlay ─────────────────────────────────────────────────────────────

class _TitleOverlay extends StatelessWidget {
  const _TitleOverlay({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black38,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
