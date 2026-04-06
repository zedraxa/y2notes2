import 'package:flutter/material.dart';
import 'package:y2notes2/core/utils/math_utils.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Chalk Effect — noise-based alpha gaps simulating chalk on a blackboard.
///
/// Uses a deterministic pseudo-random function seeded by point position to
/// create texture/gaps in the stroke alpha.
class ChalkEffect implements WritingEffect {
  ChalkEffect();

  @override
  final String id = 'chalk';

  @override
  final String name = 'Chalk';

  @override
  final String description =
      'Gives strokes a rough chalk-on-blackboard texture with realistic '
      'gaps and grain.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_ChalkDot> _dots = [];

  @override
  void onStrokeStart(PointData point) =>
      _addChalkDots(point, null);

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) =>
      _addChalkDots(point, previous, color: activeStroke.color);

  void _addChalkDots(PointData point, PointData? previous, {Color? color}) {
    final baseColor = color ?? const Color(0xFFFFFFFF);
    // Place chalk texture dots at this point
    final noiseVal = MathUtils.pseudoRandom(point.x, point.y);

    // Skip ~30% of points based on noise (creates gaps)
    if (noiseVal < 0.3 * intensity) return;

    final count = (3 + (noiseVal * 5).round()) ~/ 1;
    for (int i = 0; i < count; i++) {
      final ox = MathUtils.pseudoRandom(point.x + i, point.y, 1) * 6 - 3;
      final oy = MathUtils.pseudoRandom(point.x + i, point.y, 2) * 6 - 3;
      final noiseAlpha =
          MathUtils.pseudoRandom(point.x + ox, point.y + oy, 3);

      _dots.add(_ChalkDot(
        position: Offset(point.x + ox, point.y + oy),
        radius: 0.5 + noiseAlpha * 1.5,
        opacity: (noiseAlpha * 0.7 * intensity).clamp(0.0, 1.0),
        color: baseColor,
        age: 0.0,
        lifetime: 0.6,
      ));
    }
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {}

  @override
  void update(double dt) {
    for (final d in _dots) {
      d.age += dt;
    }
    _dots.removeWhere((d) => d.age >= d.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final dot in _dots) {
      final t = (dot.age / dot.lifetime).clamp(0.0, 1.0);
      final opacity = (dot.opacity * (1.0 - t)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = dot.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dot.position, dot.radius, paint);
    }
  }

  @override
  void dispose() => _dots.clear();
}

class _ChalkDot {
  _ChalkDot({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.color,
    required this.age,
    required this.lifetime,
  });

  final Offset position;
  final double radius;
  final double opacity;
  final Color color;
  double age;
  final double lifetime;
}
