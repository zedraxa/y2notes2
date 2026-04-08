import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Biscuits app logo — a warm, friendly biscuit/cookie motif
/// rendered entirely with Flutter's painting API.
///
/// Use [size] to control the overall dimensions. The logo scales to fit.
class BiscuitsLogo extends StatelessWidget {
  const BiscuitsLogo({
    super.key,
    this.size = 80,
    this.showText = true,
  });

  /// The width & height of the logo icon area.
  final double size;

  /// Whether to display the "Biscuits" text label below the icon.
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _BiscuitIconPainter(isDark: isDark),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.12),
          Text(
            'Biscuits',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark
                  ? const Color(0xFFF5E6D3)
                  : const Color(0xFF3D2B1F),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter that draws a stylised biscuit icon.
///
/// The design is a circular cookie shape with a warm golden gradient,
/// subtle chocolate chip dots, and a scalloped edge — conveying warmth
/// and friendliness.
class _BiscuitIconPainter extends CustomPainter {
  _BiscuitIconPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // ── Background circle (shadow) ──────────────────────────────────────
    canvas.drawCircle(
      center + Offset(0, size.height * 0.02),
      radius * 1.05,
      Paint()
        ..color = (isDark
                ? const Color(0xFF1A1210)
                : const Color(0xFF8B6914))
            .withOpacity(0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.08),
    );

    // ── Main biscuit body ───────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.2,
        colors: isDark
            ? const [Color(0xFFD4A574), Color(0xFFB8864E)]
            : const [Color(0xFFE8C99B), Color(0xFFD4A574)],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    // Scalloped edge path
    final bodyPath = Path();
    const scallops = 12;
    final scallop = radius * 0.08;
    for (var i = 0; i < scallops; i++) {
      final angle = (i / scallops) * 2 * math.pi;
      final nextAngle = ((i + 1) / scallops) * 2 * math.pi;
      final midAngle = (angle + nextAngle) / 2;

      final start = center +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          );
      final mid = center +
          Offset(
            math.cos(midAngle) * (radius + scallop),
            math.sin(midAngle) * (radius + scallop),
          );
      final end = center +
          Offset(
            math.cos(nextAngle) * radius,
            math.sin(nextAngle) * radius,
          );

      if (i == 0) bodyPath.moveTo(start.dx, start.dy);
      bodyPath.quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    }
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // ── Subtle texture ring ─────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04
        ..color = (isDark
                ? const Color(0xFFC09050)
                : const Color(0xFFCCA870))
            .withOpacity(0.5),
    );

    // ── Chocolate chip dots ─────────────────────────────────────────────
    final chipPaint = Paint()
      ..color =
          isDark ? const Color(0xFF5C3D2E) : const Color(0xFF6B4226);

    final chipPositions = <Offset>[
      center + Offset(-radius * 0.25, -radius * 0.30),
      center + Offset(radius * 0.30, -radius * 0.15),
      center + Offset(-radius * 0.10, radius * 0.25),
      center + Offset(radius * 0.20, radius * 0.35),
      center + Offset(-radius * 0.35, radius * 0.05),
      center + Offset(radius * 0.05, -radius * 0.05),
    ];

    for (final pos in chipPositions) {
      canvas.drawCircle(pos, radius * 0.07, chipPaint);
      // Highlight on each chip
      canvas.drawCircle(
        pos + Offset(-radius * 0.015, -radius * 0.015),
        radius * 0.03,
        Paint()
          ..color = const Color(0xFF8B6914).withOpacity(0.4),
      );
    }

    // ── Central pen nib accent (notes app identity) ──────────────────────
    final nibPath = Path()
      ..moveTo(center.dx, center.dy - radius * 0.15)
      ..lineTo(center.dx - radius * 0.06, center.dy + radius * 0.10)
      ..lineTo(center.dx, center.dy + radius * 0.15)
      ..lineTo(center.dx + radius * 0.06, center.dy + radius * 0.10)
      ..close();

    canvas.drawPath(
      nibPath,
      Paint()
        ..color =
            isDark ? const Color(0xFFF5E6D3) : const Color(0xFF3D2B1F)
        ..style = PaintingStyle.fill,
    );

    // ── Shine highlight ─────────────────────────────────────────────────
    canvas.drawCircle(
      center + Offset(-radius * 0.20, -radius * 0.20),
      radius * 0.15,
      Paint()
        ..color = Colors.white.withOpacity(isDark ? 0.12 : 0.25)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, radius * 0.12),
    );
  }

  @override
  bool shouldRepaint(_BiscuitIconPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}
