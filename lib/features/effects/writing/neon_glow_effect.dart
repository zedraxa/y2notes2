import 'package:flutter/material.dart';
import 'package:biscuitse/core/utils/device_capability.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';
import 'package:biscuitse/features/effects/engine/effect_config.dart';

/// Neon Glow Effect — multi-layer outer glow behind strokes.
///
/// Renders 2–3 shadow layers behind the stroke with increasing blur radius
/// and decreasing opacity. Uses [Paint.maskFilter] for blur.
class NeonGlowEffect implements WritingEffect {
  NeonGlowEffect();

  @override
  final String id = 'neon_glow';

  @override
  final String name = 'Neon Glow';

  @override
  final String description =
      'Creates a vivid neon outer glow behind every stroke, like drawing '
      'with a lit pen.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_GlowStroke> _glowStrokes = [];

  final bool _blurEnabled = DeviceCapability.supportsBlur;

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
    _glowStrokes.add(_GlowStroke(
      stroke: completedStroke,
      age: 0.0,
      lifetime: 1.5,
    ));
  }

  @override
  void update(double dt) {
    for (final g in _glowStrokes) {
      g.age += dt;
    }
    _glowStrokes.removeWhere((g) => g.age >= g.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!_blurEnabled) return;
    for (final g in _glowStrokes) {
      _renderGlow(canvas, g);
    }
  }

  void _renderGlow(Canvas canvas, _GlowStroke g) {
    final t = (g.age / g.lifetime).clamp(0.0, 1.0);
    final fade = 1.0 - t;
    final stroke = g.stroke;
    if (stroke.points.isEmpty) return;

    // Build path from points for glow overlay
    final path = Path();
    final first = stroke.points.first;
    path.moveTo(first.x, first.y);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].x, stroke.points[i].y);
    }

    final glowColor = _glowColorFor(stroke.color);

    // Layer 1 — tight glow
    _drawGlowLayer(
      canvas,
      path,
      glowColor,
      sigma: stroke.baseWidth * 0.6 * intensity,
      opacity: 0.55 * fade * intensity,
      strokeWidth: stroke.baseWidth,
    );

    // Layer 2 — medium glow
    _drawGlowLayer(
      canvas,
      path,
      glowColor,
      sigma: stroke.baseWidth * 1.5 * intensity,
      opacity: 0.30 * fade * intensity,
      strokeWidth: stroke.baseWidth * 1.4,
    );

    // Layer 3 — wide soft halo
    _drawGlowLayer(
      canvas,
      path,
      glowColor,
      sigma: stroke.baseWidth * 3.0 * intensity,
      opacity: 0.15 * fade * intensity,
      strokeWidth: stroke.baseWidth * 2.0,
    );
  }

  void _drawGlowLayer(
    Canvas canvas,
    Path path,
    Color color, {
    required double sigma,
    required double opacity,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    canvas.drawPath(path, paint);
  }

  /// Choose a vivid glow color complementary to the stroke color.
  Color _glowColorFor(Color base) {
    final hsv = HSVColor.fromColor(base);
    // Boost saturation and shift slightly warmer
    return hsv
        .withSaturation((hsv.saturation * 1.3).clamp(0.0, 1.0))
        .withValue(1.0)
        .toColor();
  }

  @override
  void dispose() => _glowStrokes.clear();
}

class _GlowStroke {
  _GlowStroke({
    required this.stroke,
    required this.age,
    required this.lifetime,
  });

  final Stroke stroke;
  double age;
  final double lifetime;
}
