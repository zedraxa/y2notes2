import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/core/utils/math_utils.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/effects/engine/effect_config.dart';

/// Rainbow Ink Effect — enhanced hue cycling along the stroke path.
///
/// Improvements over basic linear hue rotation:
/// - Velocity-responsive cycle speed: fast strokes cycle faster
/// - Smooth cubic easing between hue transitions
/// - Outer glow halo for vivid neon-rainbow look
/// - Saturation pulsing: gentle oscillation for liveliness
/// - Longer lifetime and smoother fade-out
class RainbowInkEffect implements WritingEffect {
  RainbowInkEffect();

  @override
  final String id = 'rainbow_ink';

  @override
  final String name = 'Rainbow Ink';

  @override
  final String description =
      'The stroke colour smoothly cycles through the rainbow as you draw.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_RainbowSegment> _segments = [];

  @override
  void onStrokeStart(PointData point) {}

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {
    if (previous == null) return;

    // Cumulative distance from the start of the stroke to this point
    double dist = 0.0;
    final pts = activeStroke.points;
    for (int i = 1; i < pts.length; i++) {
      dist += MathUtils.distance(
        Offset(pts[i - 1].x, pts[i - 1].y),
        Offset(pts[i].x, pts[i].y),
      );
    }

    // Velocity-responsive cycle speed: faster strokes cycle proportionally faster
    final velocity = point.velocity.clamp(0.1, 5.0);
    final speedMultiplier = 0.7 + velocity * 0.3;
    final adjustedCycle = AppConstants.rainbowDistanceCycle / speedMultiplier;

    // Smooth cubic easing for hue transition (not purely linear)
    final rawHue = (dist / adjustedCycle * 360.0) % 360.0;
    final easedHue = _smoothHue(rawHue);

    // Saturation pulsing: gentle oscillation tied to distance
    final satPulse = 0.85 + 0.15 * math.sin(dist * 0.02 * intensity);
    final color = MathUtils.colorFromHue(
      easedHue,
      saturation: satPulse.clamp(0.7, 1.0),
      value: 0.95,
    );

    _segments.add(_RainbowSegment(
      from: Offset(previous.x, previous.y),
      to: Offset(point.x, point.y),
      color: color,
      width: activeStroke.baseWidth,
      age: 0.0,
      lifetime: 1.2,
    ));
  }

  /// Smooth hue transition using sine interpolation for gentle colour flow.
  double _smoothHue(double hue) {
    // Apply a gentle sine modulation to soften the linear ramp
    final normalised = hue / 360.0;
    final smoothed = normalised + 0.03 * math.sin(normalised * math.pi * 4);
    return (smoothed * 360.0) % 360.0;
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {}

  @override
  void update(double dt) {
    for (final s in _segments) {
      s.age += dt;
    }
    _segments.removeWhere((s) => s.age >= s.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final seg in _segments) {
      final t = (seg.age / seg.lifetime).clamp(0.0, 1.0);
      // Smooth ease-out fade: stays visible longer then drops off
      final fadeCurve = 1.0 - t * t;
      final opacity = fadeCurve * 0.7 * intensity;
      if (opacity < 0.01) continue;

      // ── Layer 1 — Outer glow halo for neon rainbow look ─────────────────
      final glowOpacity = (opacity * 0.25).clamp(0.0, 1.0);
      if (glowOpacity > 0.01) {
        final glowPaint = Paint()
          ..color = seg.color.withOpacity(glowOpacity)
          ..strokeWidth = seg.width * 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawLine(seg.from, seg.to, glowPaint);
      }

      // ── Layer 2 — Main rainbow stroke ───────────────────────────────────
      final mainPaint = Paint()
        ..color = seg.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..strokeWidth = seg.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(seg.from, seg.to, mainPaint);

      // ── Layer 3 — Bright core highlight ─────────────────────────────────
      final coreOpacity = (opacity * 0.3).clamp(0.0, 1.0);
      if (coreOpacity > 0.01) {
        final corePaint = Paint()
          ..color = Colors.white.withOpacity(coreOpacity)
          ..strokeWidth = seg.width * 0.3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(seg.from, seg.to, corePaint);
      }
    }
  }

  @override
  void dispose() => _segments.clear();
}

class _RainbowSegment {
  _RainbowSegment({
    required this.from,
    required this.to,
    required this.color,
    required this.width,
    required this.age,
    required this.lifetime,
  });

  final Offset from;
  final Offset to;
  final Color color;
  final double width;
  double age;
  final double lifetime;
}
