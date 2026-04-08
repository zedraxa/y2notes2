import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a realistic stylus-nib preview at a hover position.
///
/// The nib is a teardrop shape whose orientation follows the pen's [azimuth]
/// angle, and whose apparent height shrinks as [tilt] approaches π/2
/// (perfectly vertical pen).  A soft drop-shadow is drawn to reinforce the
/// impression that the tip is floating just above the canvas surface.
///
/// **Coordinate convention** (matches Flutter's [PointerEvent]):
/// - [tilt] (altitude) — 0 = pen flat on screen, π/2 = pen perpendicular.
/// - [azimuth] (orientation) — 0 = pen tip pointing right (+x), increases
///   counter-clockwise.
///
/// Usage:
/// ```dart
/// CustomPaint(
///   painter: GhostNibPainter(
///     color: activeColor,
///     brushSize: activeWidth,
///     tilt: hoverTilt,
///     azimuth: hoverAzimuth,
///     isEraser: false,
///   ),
///   size: const Size(72, 72), // provide enough room for nib + shadow
/// )
/// ```
class GhostNibPainter extends CustomPainter {
  const GhostNibPainter({
    required this.color,
    required this.brushSize,
    required this.tilt,
    required this.azimuth,
    this.isEraser = false,
  });

  /// Active tool colour; determines nib fill tint.
  final Color color;

  /// Brush tip diameter in logical pixels; clamps to a visible range.
  final double brushSize;

  /// Pen altitude angle from the screen plane [0, π/2].
  final double tilt;

  /// Pen azimuth (orientation) in the screen plane [0, 2π).
  final double azimuth;

  /// When `true`, renders the eraser nib (white/grey palette).
  final bool isEraser;

  // ─── Geometry constants ────────────────────────────────────────────────────

  /// How many logical pixels the nib body extends from the contact point.
  static const double _nibLength = 28.0;

  /// Maximum drop-shadow offset (at tilt = 0, pen is completely flat).
  static const double _maxShadowOffset = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Derived geometry ──────────────────────────────────────────────────────
    // `tilt` 0 = flat → long nib; π/2 = vertical → small nib like a circle.
    final normalizedTilt = (tilt / (math.pi / 2)).clamp(0.0, 1.0);

    // The nib is drawn pointing "up" in local space, then rotated to match the
    // azimuth angle.  Flutter's orientation is counter-clockwise from +x, so
    // we subtract π/2 to point the nib along the pen direction.
    final rotationAngle = -(azimuth - math.pi / 2);

    // Nib body dimensions shrink as tilt increases (pen is more vertical).
    final nibHeight = _nibLength * (1.0 - normalizedTilt * 0.6);
    final nibWidth = brushSize.clamp(4.0, 20.0) * (0.5 + normalizedTilt * 0.5);

    // Shadow offset: long when pen is flat, zero when perfectly vertical.
    final shadowLength = _maxShadowOffset * (1.0 - normalizedTilt);

    // ── Shadow ─────────────────────────────────────────────────────────────────
    if (shadowLength > 1.0) {
      // Shadow is cast in the direction the pen top leans toward (anti-azimuth).
      final shadowDx = math.cos(azimuth + math.pi) * shadowLength;
      final shadowDy = math.sin(azimuth + math.pi) * shadowLength;

      final shadowPath = _buildNibPath(
        center + Offset(shadowDx, shadowDy),
        nibWidth * 0.9,
        nibHeight * 0.85,
      );
      canvas.save();
      canvas.translate(
          center.dx + shadowDx, center.dy + shadowDy);
      canvas.rotate(rotationAngle);
      canvas.translate(-center.dx - shadowDx, -center.dy - shadowDy);

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.12 * (1.0 - normalizedTilt))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
      canvas.restore();
    }

    // ── Nib body ───────────────────────────────────────────────────────────────
    final nibPath = _buildNibPath(center, nibWidth, nibHeight);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Fill
    final fillColor = isEraser
        ? Colors.white.withValues(alpha: 0.75)
        : color.withValues(alpha: 0.30);
    canvas.drawPath(nibPath, Paint()..color = fillColor..style = PaintingStyle.fill);

    // Outline
    final outlineColor = isEraser
        ? Colors.grey.shade500.withValues(alpha: 0.85)
        : color.withValues(alpha: 0.85);
    canvas.drawPath(
      nibPath,
      Paint()
        ..color = outlineColor
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );

    canvas.restore();

    // ── Contact-point dot ──────────────────────────────────────────────────────
    // Small filled circle at the exact contact point to show where ink will land.
    final dotColor = isEraser ? Colors.grey.shade400 : color;
    final dotRadius = (brushSize * 0.12).clamp(1.5, 4.0);
    canvas.drawCircle(
      center,
      dotRadius,
      Paint()..color = dotColor..style = PaintingStyle.fill,
    );
  }

  /// Builds a teardrop path centred on [origin].
  ///
  /// The tip points downward (toward the contact point, before rotation).
  /// The body is an ellipse that tapers into a point at the bottom.
  Path _buildNibPath(Offset origin, double width, double height) {
    final path = Path();
    final halfW = width / 2;
    final bodyHeight = height * 0.65; // upper elliptical portion
    final tipLength = height * 0.35; // lower tapered tip

    // Top arc of the ellipse.
    final topRect = Rect.fromCenter(
      center: origin - Offset(0, tipLength / 2),
      width: width,
      height: bodyHeight,
    );
    path.addArc(topRect, math.pi, math.pi); // top half-ellipse

    // Right side curves down to the tip.
    path.cubicTo(
      origin.dx + halfW,
      origin.dy + bodyHeight * 0.2,
      origin.dx + halfW * 0.3,
      origin.dy + tipLength * 0.8,
      origin.dx,
      origin.dy + tipLength,
    );
    // Left side curves back up.
    path.cubicTo(
      origin.dx - halfW * 0.3,
      origin.dy + tipLength * 0.8,
      origin.dx - halfW,
      origin.dy + bodyHeight * 0.2,
      origin.dx - halfW,
      origin.dy - tipLength / 2,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(GhostNibPainter old) =>
      old.color != color ||
      old.brushSize != brushSize ||
      old.tilt != tilt ||
      old.azimuth != azimuth ||
      old.isEraser != isEraser;
}
