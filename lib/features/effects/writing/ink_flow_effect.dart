import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';
import 'package:biscuitse/features/effects/engine/effect_config.dart';

/// Ink Flow Effect — ink darkens/pools at stroke start and end points.
///
/// Varies opacity based on velocity: low velocity = more ink pooling = darker.
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
    _pools.add(_InkPool(
      position: position,
      radius: radius,
      alpha: (alpha * intensity).clamp(0.0, 1.0),
      age: 0.0,
      lifetime: 1.5,
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
      final opacity = (pool.alpha * (1.0 - t)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.black.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pool.position, pool.radius * (1.0 + t * 0.3), paint);
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
  });

  final Offset position;
  final double radius;
  final double alpha;
  double age;
  final double lifetime;
}
