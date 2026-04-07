import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/utils/math_utils.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Pressure Bloom Effect — multi-ring radial spread around high-pressure points.
///
/// When pressure > 0.7, renders a 3-layer bloom: blurred outer halo, pulsing
/// mid-ring, and concentrated inner core with scattered ink dots.
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
    // Generate scatter dot angles deterministically from position
    final noise = MathUtils.pseudoRandom(point.x, point.y, 0);
    _blooms.add(_BloomPoint(
      position: Offset(point.x, point.y),
      color: Colors.black,
      radius: (excess * 30.0 * intensity).clamp(2.0, 24.0),
      age: 0.0,
      lifetime: 0.8,
      scatterSeed: noise,
      excess: excess,
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
      final fade = 1.0 - t;

      // Layer 1 — soft outer halo with radial gradient
      final haloRadius = b.radius * (1.0 + t * 0.8);
      final haloOpacity = (0.12 * intensity * fade).clamp(0.0, 1.0);
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withOpacity(haloOpacity),
            b.color.withOpacity(haloOpacity * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
          Rect.fromCircle(center: b.position, radius: haloRadius),
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(b.position, haloRadius, haloPaint);

      // Layer 2 — pulsing mid-ring (sine-wave modulated opacity)
      final pulsePhase = math.sin(t * math.pi * 3) * 0.5 + 0.5;
      final midRadius = b.radius * (0.7 + t * 0.4);
      final midOpacity =
          (0.15 * intensity * fade * (0.5 + pulsePhase * 0.5)).clamp(0.0, 1.0);
      final midPaint = Paint()
        ..color = b.color.withOpacity(midOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * intensity;
      canvas.drawCircle(b.position, midRadius, midPaint);

      // Layer 3 — concentrated inner core fill
      final coreRadius = b.radius * (0.4 + t * 0.15);
      final coreOpacity = (0.22 * intensity * fade).clamp(0.0, 1.0);
      final corePaint = Paint()
        ..color = b.color.withOpacity(coreOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(b.position, coreRadius, corePaint);

      // Layer 4 — scattered ink dots radiating outward
      final dotCount = (3 + b.excess * 8).round().clamp(2, 6);
      for (int i = 0; i < dotCount; i++) {
        final angle = (b.scatterSeed + i / dotCount) * math.pi * 2;
        final dist = b.radius * (0.5 + t * 0.6);
        final dotPos = b.position + Offset(math.cos(angle), math.sin(angle)) * dist;
        final dotOpacity = (0.2 * intensity * fade * (1.0 - i / dotCount))
            .clamp(0.0, 1.0);
        final dotPaint = Paint()
          ..color = b.color.withOpacity(dotOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dotPos, 1.0 + b.excess * 2.0, dotPaint);
      }
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
    required this.scatterSeed,
    required this.excess,
  });

  final Offset position;
  final Color color;
  final double radius;
  double age;
  final double lifetime;
  final double scatterSeed;
  final double excess;
}
