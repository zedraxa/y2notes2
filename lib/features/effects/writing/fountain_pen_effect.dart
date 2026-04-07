import 'package:flutter/material.dart';
import 'package:biscuitse/core/constants/app_constants.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';
import 'package:biscuitse/features/effects/engine/effect_config.dart';

/// Fountain Pen Variation Effect — calligraphic width modulation.
///
/// Downward strokes get wider; upward strokes get narrower, recreating the
/// classic broad-nib calligraphy look.
class FountainPenEffect implements WritingEffect {
  FountainPenEffect();

  @override
  final String id = 'fountain_pen';

  @override
  final String name = 'Fountain Pen';

  @override
  final String description =
      'Downward strokes become bolder and upward strokes finer, '
      'mimicking a classic calligraphy nib.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  // Rendered line segments with per-segment width
  final List<_CalligraphySegment> _segments = [];
  PointData? _lastPoint;

  @override
  void onStrokeStart(PointData point) => _lastPoint = point;

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {
    if (_lastPoint == null) {
      _lastPoint = point;
      return;
    }

    final prev = _lastPoint!;
    final dy = point.y - prev.y;

    // Determine width multiplier based on vertical direction
    final double widthScale;
    if (dy > 0) {
      // Downward stroke — bold
      widthScale = AppConstants.fountainDownScale * intensity;
    } else if (dy < 0) {
      // Upward stroke — thin
      widthScale = AppConstants.fountainUpScale / intensity.clamp(0.5, 2.0);
    } else {
      widthScale = 1.0;
    }

    _segments.add(_CalligraphySegment(
      from: Offset(prev.x, prev.y),
      to: Offset(point.x, point.y),
      width: activeStroke.baseWidth * widthScale,
      color: activeStroke.color,
      age: 0.0,
      lifetime: 1.0,
    ));

    _lastPoint = point;
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {
    _lastPoint = null;
  }

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
      final opacity = (1.0 - t * 0.8).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = seg.color.withOpacity(opacity * 0.4)
        ..strokeWidth = seg.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(seg.from, seg.to, paint);
    }
  }

  @override
  void dispose() {
    _segments.clear();
    _lastPoint = null;
  }
}

class _CalligraphySegment {
  _CalligraphySegment({
    required this.from,
    required this.to,
    required this.width,
    required this.color,
    required this.age,
    required this.lifetime,
  });

  final Offset from;
  final Offset to;
  final double width;
  final Color color;
  double age;
  final double lifetime;
}
