import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/core/utils/math_utils.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Watercolor Bleed Effect — feathered, soft stroke edges.
///
/// Adds slight random displacement to stroke edge points and reduces alpha
/// at edges, creating a feathered watercolor look.
class WatercolorBleedEffect implements WritingEffect {
  WatercolorBleedEffect();

  @override
  final String id = 'watercolor_bleed';

  @override
  final String name = 'Watercolor Bleed';

  @override
  final String description =
      'Softens stroke edges with gentle watercolor-style feathering and '
      'colour bleeding.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_WatercolorStroke> _renders = [];
  final math.Random _random = math.Random();

  @override
  void onStrokeStart(PointData point) {}

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {}

  @override
  void onStrokeEnd(Stroke completedStroke) {
    if (completedStroke.points.isEmpty) return;
    // Pre-bake bleed offsets for each point
    final offsets = completedStroke.points
        .map((p) => _randomOffset(intensity * 3.0))
        .toList();
    _renders.add(_WatercolorStroke(
      stroke: completedStroke,
      offsets: offsets,
      age: 0.0,
      lifetime: 2.0,
    ));
  }

  Offset _randomOffset(double maxDisplace) => Offset(
        (_random.nextDouble() - 0.5) * 2 * maxDisplace,
        (_random.nextDouble() - 0.5) * 2 * maxDisplace,
      );

  @override
  void update(double dt) {
    for (final r in _renders) {
      r.age += dt;
    }
    _renders.removeWhere((r) => r.age >= r.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final r in _renders) {
      _renderBleed(canvas, r);
    }
  }

  void _renderBleed(Canvas canvas, _WatercolorStroke r) {
    final t = (r.age / r.lifetime).clamp(0.0, 1.0);
    final fade = (1.0 - t * 0.7).clamp(0.0, 1.0);
    final pts = r.stroke.points;
    if (pts.length < 2) return;

    for (int pass = 0; pass < 2; pass++) {
      final path = Path();
      final bleed = intensity * (pass == 0 ? 2.0 : 5.0);
      final alpha = (pass == 0 ? 0.12 : 0.06) * fade * intensity;

      path.moveTo(
        pts[0].x + r.offsets[0].dx * bleed,
        pts[0].y + r.offsets[0].dy * bleed,
      );
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(
          pts[i].x + r.offsets[i].dx * bleed,
          pts[i].y + r.offsets[i].dy * bleed,
        );
      }

      final paint = Paint()
        ..color = r.stroke.color
            .withOpacity(alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.stroke.baseWidth * (1.0 + pass * 0.6)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    }
  }

  @override
  void dispose() => _renders.clear();
}

class _WatercolorStroke {
  _WatercolorStroke({
    required this.stroke,
    required this.offsets,
    required this.age,
    required this.lifetime,
  });

  final Stroke stroke;
  final List<Offset> offsets;
  double age;
  final double lifetime;
}
