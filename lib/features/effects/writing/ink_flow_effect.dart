import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/core/utils/math_utils.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/effects/engine/effect_config.dart';

/// Ink Flow Effect — ink darkens/pools at stroke start and end points.
///
/// Multi-layer rendering with radial gradient pools, noise-based edge
/// turbulence, and velocity-dependent spread. Slower strokes produce richer,
/// darker pools with feathered edges.
class InkFlowEffect implements WritingEffect {
  InkFlowEffect();

  @override
  final String id = 'ink_flow';

  @override
  final String name = 'Ink Flow';

  @override
  final String description =
      'Ink darkens and pools at the start and end of strokes. '
      'Slower strokes produce richer, darker lines.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_InkPool> _pools = [];

  @override
  void onStrokeStart(PointData point) {
    _addPool(Offset(point.x, point.y), point.pressure, alpha: 0.5);
  }

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {
    // At slow velocity, add subtle pooling along the stroke
    if (point.velocity < 0.3) {
      _addPool(Offset(point.x, point.y), point.pressure, alpha: 0.15);
    }
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {
    if (completedStroke.points.isEmpty) return;
    final last = completedStroke.points.last;
    _addPool(Offset(last.x, last.y), last.pressure, alpha: 0.4);
  }

  void _addPool(Offset position, double pressure, {required double alpha}) {
    final radius = (4 + pressure * 8) * intensity;
    // Noise-based turbulence offsets for organic edge distortion
    final noise1 = MathUtils.pseudoRandom(position.dx, position.dy, 0);
    final noise2 = MathUtils.pseudoRandom(position.dx, position.dy, 1);
    _pools.add(_InkPool(
      position: position,
      radius: radius,
      alpha: (alpha * intensity).clamp(0.0, 1.0),
      age: 0.0,
      lifetime: 1.5,
      turbulenceAngle: noise1 * math.pi * 2,
      turbulenceOffset: noise2 * 3.0 * intensity,
    ));
  }

  @override
  void update(double dt) {
    for (final pool in _pools) {
      pool.age += dt;
    }
    _pools.removeWhere((p) => p.age >= p.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final pool in _pools) {
      final t = pool.age / pool.lifetime;
      final fade = 1.0 - t;
      final expandedRadius = pool.radius * (1.0 + t * 0.3);

      // Turbulence shifts the pool center slightly for organic feel
      final turbOffset = Offset(
        math.cos(pool.turbulenceAngle) * pool.turbulenceOffset * t,
        math.sin(pool.turbulenceAngle) * pool.turbulenceOffset * t,
      );
      final center = pool.position + turbOffset;

      // Layer 1 — soft outer feathered edge (radial gradient)
      final outerRadius = expandedRadius * 1.6;
      final outerOpacity = (pool.alpha * 0.25 * fade).clamp(0.0, 1.0);
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withOpacity(outerOpacity),
            Colors.black.withOpacity(outerOpacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, outerRadius, gradientPaint);

      // Layer 2 — dark concentrated core
      final coreOpacity = (pool.alpha * fade).clamp(0.0, 1.0);
      final corePaint = Paint()
        ..color = Colors.black.withOpacity(coreOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, expandedRadius * 0.6, corePaint);

      // Layer 3 — mid-tone blended ring between core and edge
      final midOpacity = (pool.alpha * 0.5 * fade).clamp(0.0, 1.0);
      final midPaint = Paint()
        ..color = Colors.black.withOpacity(midOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, expandedRadius, midPaint);
    }
  }

  @override
  void dispose() => _pools.clear();
}

class _InkPool {
  _InkPool({
    required this.position,
    required this.radius,
    required this.alpha,
    required this.age,
    required this.lifetime,
    required this.turbulenceAngle,
    required this.turbulenceOffset,
  });

  final Offset position;
  final double radius;
  final double alpha;
  double age;
  final double lifetime;
  final double turbulenceAngle;
  final double turbulenceOffset;
}
