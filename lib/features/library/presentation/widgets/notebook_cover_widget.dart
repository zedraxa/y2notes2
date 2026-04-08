import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';

/// Renders a stylised notebook cover thumbnail.
///
/// Accepts a [color] and [material] and draws:
///   - A base colored rectangle with a spine on the left.
///   - A subtle material texture overlay (grain, weave, etc.) controlled
///     by [material].
///   - An optional [title] drawn over the cover.
class NotebookCoverWidget extends StatelessWidget {
  const NotebookCoverWidget({
    super.key,
    required this.color,
    this.material = CoverMaterial.matte,
    this.title,
    this.width = 120,
    this.height = 160,
  });

  final Color color;
  final CoverMaterial material;
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
        ),
        child: title != null ? _TitleOverlay(title: title!) : null,
      ),
    );
  }
}

// ── Cover painter ─────────────────────────────────────────────────────────────

class _CoverPainter extends CustomPainter {
  _CoverPainter({required this.color, required this.material});

  final Color color;
  final CoverMaterial material;

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
      old.color != color || old.material != material;
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
