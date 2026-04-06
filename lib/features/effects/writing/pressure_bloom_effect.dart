import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Pressure Bloom Effect — radial spread around high-pressure points.
///
/// When pressure > 0.7, renders semi-transparent circles behind the stroke.
class PressureBloomEffect implements WritingEffect {
  PressureBloomEffect();

  @override
  final String id = 'pressure_bloom';

  @override
  final String name = 'Pressure Bloom';

  @override
  final String description =
      'Adds a subtle radial bloom around points where you press harder. '
      'Creates a natural pressure-sensitive ink spread.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_BloomPoint> _blooms = [];

  @override
  void onStrokeStart(PointData point) => _tryAddBloom(point);

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) =>
      _tryAddBloom(point);

  @override
  void onStrokeEnd(Stroke completedStroke) {}

  void _tryAddBloom(PointData point) {
    if (point.pressure < AppConstants.bloomPressureThreshold) return;
    final excess = point.pressure - AppConstants.bloomPressureThreshold;
    _blooms.add(_BloomPoint(
      position: Offset(point.x, point.y),
      color: Colors.black,
      radius: (excess * 30.0 * intensity).clamp(2.0, 24.0),
      age: 0.0,
      lifetime: 0.8,
    ));
  }

  @override
  void update(double dt) {
    for (final b in _blooms) {
      b.age += dt;
    }
    _blooms.removeWhere((b) => b.age >= b.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final b in _blooms) {
      final t = b.age / b.lifetime;
      final opacity = (0.18 * intensity * (1.0 - t)).clamp(0.0, 1.0);
      final expandedRadius = b.radius * (1.0 + t * 0.5);
      final paint = Paint()
        ..color = b.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(b.position, expandedRadius, paint);
    }
  }

  @override
  void dispose() => _blooms.clear();
}

class _BloomPoint {
  _BloomPoint({
    required this.position,
    required this.color,
    required this.radius,
    required this.age,
    required this.lifetime,
  });

  final Offset position;
  final Color color;
  final double radius;
  double age;
  final double lifetime;
}
