import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/core/utils/math_utils.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/effects/engine/effect_config.dart';

/// Watercolor Bleed Effect — organic, multi-pass feathered stroke edges.
///
/// Enhanced rendering with:
/// - 4-pass bleed layers at different displacement scales for depth
/// - Perlin-style noise displacement via pseudoRandom for organic shapes
/// - Color diffusion: outer passes shift hue slightly toward neighbours
/// - Wet-edge darkening along stroke edges
/// - Animated expansion: bleed slowly spreads outward over the lifetime
/// - Smooth fade-out with eased opacity curve
class WatercolorBleedEffect implements WritingEffect {
  WatercolorBleedEffect();

  @override
  final String id = 'watercolor_bleed';

  @override
  final String name = 'Watercolor Bleed';

  @override
  final String description =
      'Softens stroke edges with gentle watercolor-style feathering and '
      'color bleeding.';

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

    // Pre-bake noise-based offsets per point for multiple displacement layers
    final pts = completedStroke.points;
    final offsets1 = <Offset>[];
    final offsets2 = <Offset>[];
    final offsets3 = <Offset>[];
    final offsets4 = <Offset>[];

    for (int i = 0; i < pts.length; i++) {
      final p = pts[i];
      // Use different seeds for independent noise per layer
      offsets1.add(_noiseOffset(p.x, p.y, 0, intensity * 2.5));
      offsets2.add(_noiseOffset(p.x, p.y, 7, intensity * 5.0));
      offsets3.add(_noiseOffset(p.x, p.y, 13, intensity * 8.0));
      offsets4.add(_noiseOffset(p.x, p.y, 19, intensity * 12.0));
    }

    _renders.add(_WatercolorStroke(
      stroke: completedStroke,
      layerOffsets: [offsets1, offsets2, offsets3, offsets4],
      age: 0.0,
      lifetime: 2.5,
    ));
  }

  /// Generate a noise-based displacement offset using pseudoRandom.
  Offset _noiseOffset(double x, double y, int seed, double maxDisplace) {
    // Multi-octave pseudo-noise for more organic displacement
    final n1 = MathUtils.pseudoRandom(x, y, seed);
    final n2 = MathUtils.pseudoRandom(x * 0.5, y * 0.5, seed + 1);
    final combined = (n1 * 0.7 + n2 * 0.3); // blend octaves
    final angle = combined * math.pi * 2;
    final magnitude = MathUtils.pseudoRandom(x + seed, y + seed, seed + 2) * maxDisplace;
    return Offset(math.cos(angle) * magnitude, math.sin(angle) * magnitude);
  }

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
    // Smooth fade: stays visible longer, then fades quickly at the end
    final fade = (1.0 - t * t).clamp(0.0, 1.0);
    final pts = r.stroke.points;
    if (pts.length < 2) return;

    // Animated expansion: bleed grows outward over time
    final expansionFactor = 1.0 + t * 0.4;

    // 4 bleed passes from tight to wide
    const passConfigs = [
      (widthMult: 1.0, alphaMult: 0.14, hueDrift: 0.0),
      (widthMult: 1.4, alphaMult: 0.09, hueDrift: 5.0),
      (widthMult: 1.9, alphaMult: 0.05, hueDrift: -8.0),
      (widthMult: 2.5, alphaMult: 0.025, hueDrift: 12.0),
    ];

    for (int pass = 0; pass < passConfigs.length; pass++) {
      final config = passConfigs[pass];
      final offsets = r.layerOffsets[pass];
      final alpha = config.alphaMult * fade * intensity;
      if (alpha < 0.005) continue;

      // Color diffusion: outer passes shift hue slightly
      final bleedColor = config.hueDrift != 0.0
          ? _shiftHue(r.stroke.color, config.hueDrift * intensity)
          : r.stroke.color;

      final path = Path();
      path.moveTo(
        pts[0].x + offsets[0].dx * expansionFactor,
        pts[0].y + offsets[0].dy * expansionFactor,
      );
      for (int i = 1; i < pts.length; i++) {
        // Use quadratic bezier for smoother curves between displaced points
        if (i < pts.length - 1) {
          final midX = (pts[i].x + offsets[i].dx * expansionFactor +
                  pts[i + 1].x + offsets[i + 1].dx * expansionFactor) *
              0.5;
          final midY = (pts[i].y + offsets[i].dy * expansionFactor +
                  pts[i + 1].y + offsets[i + 1].dy * expansionFactor) *
              0.5;
          path.quadraticBezierTo(
            pts[i].x + offsets[i].dx * expansionFactor,
            pts[i].y + offsets[i].dy * expansionFactor,
            midX,
            midY,
          );
        } else {
          path.lineTo(
            pts[i].x + offsets[i].dx * expansionFactor,
            pts[i].y + offsets[i].dy * expansionFactor,
          );
        }
      }

      final paint = Paint()
        ..color = bleedColor.withOpacity(alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.stroke.baseWidth * config.widthMult * expansionFactor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    }

    // ── Wet-edge darkening: thin dark line along the stroke edge ──────────
    final edgeAlpha = (0.08 * fade * intensity).clamp(0.0, 1.0);
    if (edgeAlpha > 0.005) {
      final edgePath = Path();
      final edgeOffsets = r.layerOffsets[0]; // tightest layer
      edgePath.moveTo(
        pts[0].x + edgeOffsets[0].dx * 0.3,
        pts[0].y + edgeOffsets[0].dy * 0.3,
      );
      for (int i = 1; i < pts.length; i++) {
        edgePath.lineTo(
          pts[i].x + edgeOffsets[i].dx * 0.3,
          pts[i].y + edgeOffsets[i].dy * 0.3,
        );
      }
      final edgePaint = Paint()
        ..color = _darken(r.stroke.color, 0.3).withOpacity(edgeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.stroke.baseWidth * 1.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(edgePath, edgePaint);
    }
  }

  /// Shift the hue of [color] by [degrees].
  Color _shiftHue(Color color, double degrees) {
    final hsv = HSVColor.fromColor(color);
    return hsv.withHue((hsv.hue + degrees) % 360).toColor();
  }

  /// Darken a colour by [amount] (0..1, where 1 = fully black).
  Color _darken(Color color, double amount) {
    final hsv = HSVColor.fromColor(color);
    return hsv
        .withValue((hsv.value * (1.0 - amount)).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void dispose() => _renders.clear();
}

class _WatercolorStroke {
  _WatercolorStroke({
    required this.stroke,
    required this.layerOffsets,
    required this.age,
    required this.lifetime,
  });

  final Stroke stroke;
  /// Per-layer displacement offsets. layerOffsets[pass][pointIndex].
  final List<List<Offset>> layerOffsets;
  double age;
  final double lifetime;
}
