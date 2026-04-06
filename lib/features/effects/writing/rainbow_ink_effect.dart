import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/utils/math_utils.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Rainbow Ink Effect — hue cycles along the stroke path.
///
/// Maps cumulative distance to a full hue rotation every
/// [AppConstants.rainbowDistanceCycle] pixels.
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

    final hue = (dist / AppConstants.rainbowDistanceCycle * 360.0) % 360.0;
    final color = MathUtils.colorFromHue(hue, saturation: 0.9, value: 0.95);

    _segments.add(_RainbowSegment(
      from: Offset(previous.x, previous.y),
      to: Offset(point.x, point.y),
      color: color,
      width: activeStroke.baseWidth,
      age: 0.0,
      lifetime: 0.8,
    ));
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
      final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.65 * intensity;
      if (opacity < 0.01) continue;
      final paint = Paint()
        ..color = seg.color.withOpacity(opacity)
        ..strokeWidth = seg.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(seg.from, seg.to, paint);
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
