import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/core/utils/math_utils.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/effects/engine/effect_config.dart';

/// Chalk Effect — multi-layer chalk-on-blackboard texture.
///
/// Enhanced rendering with:
/// - Multi-size grain particles: fine dust + coarser chunks
/// - Streak lines along the stroke direction for realistic chalk drag
/// - Edge scatter: particles thrown outward from the stroke edge
/// - Dust cloud: very faint large-radius particles for airborne chalk feel
/// - Pressure-responsive density: harder press = denser texture
/// - Longer lifetime with eased fade-out
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

  final List<_ChalkElement> _elements = [];

  @override
  void onStrokeStart(PointData point) =>
      _addChalkTexture(point, null);

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) =>
      _addChalkTexture(point, previous, color: activeStroke.color);

  void _addChalkTexture(PointData point, PointData? previous,
      {Color? color}) {
    final baseColor = color ?? const Color(0xFFFFFFFF);
    final noiseVal = MathUtils.pseudoRandom(point.x, point.y);

    // Gap frequency based on noise (creates natural chalk breaks)
    if (noiseVal < 0.25 * intensity) return;

    // Pressure-responsive density: harder press = more particles
    final pressureMult = 0.6 + point.pressure * 0.8;

    // ── Layer 1: Fine grain dust (many small dots) ─────────────────────────
    final fineCount = ((3 + noiseVal * 6) * pressureMult).round().clamp(2, 10);
    for (int i = 0; i < fineCount; i++) {
      final ox = MathUtils.pseudoRandom(point.x + i, point.y, 1) * 8 - 4;
      final oy = MathUtils.pseudoRandom(point.x + i, point.y, 2) * 8 - 4;
      final noiseAlpha =
          MathUtils.pseudoRandom(point.x + ox, point.y + oy, 3);

      _elements.add(_ChalkElement(
        position: Offset(point.x + ox, point.y + oy),
        radius: 0.4 + noiseAlpha * 1.2,
        opacity: (noiseAlpha * 0.65 * intensity).clamp(0.0, 1.0),
        color: baseColor,
        age: 0.0,
        lifetime: 1.0,
        type: _ChalkElementType.dot,
      ));
    }

    // ── Layer 2: Coarser chunks (fewer, larger, more opaque) ───────────────
    final chunkNoise = MathUtils.pseudoRandom(point.x, point.y, 4);
    if (chunkNoise > 0.6) {
      final chunkCount = (1 + (chunkNoise * 2).round()).clamp(1, 3);
      for (int i = 0; i < chunkCount; i++) {
        final ox = MathUtils.pseudoRandom(point.x + i * 7, point.y, 5) * 6 - 3;
        final oy = MathUtils.pseudoRandom(point.x + i * 7, point.y, 6) * 6 - 3;
        _elements.add(_ChalkElement(
          position: Offset(point.x + ox, point.y + oy),
          radius: 1.5 + chunkNoise * 2.0,
          opacity: (chunkNoise * 0.4 * intensity).clamp(0.0, 1.0),
          color: baseColor,
          age: 0.0,
          lifetime: 1.2,
          type: _ChalkElementType.dot,
        ));
      }
    }

    // ── Layer 3: Streak lines along stroke direction ───────────────────────
    if (previous != null) {
      final dx = point.x - previous.x;
      final dy = point.y - previous.y;
      final segLen = math.sqrt(dx * dx + dy * dy);
      if (segLen > 1.0) {
        final streakNoise = MathUtils.pseudoRandom(point.x, point.y, 7);
        if (streakNoise > 0.4) {
          // Normalised direction
          final nx = dx / segLen;
          final ny = dy / segLen;
          // Perpendicular offset for streak placement
          final perpX = -ny;
          final perpY = nx;
          final perpOff =
              (MathUtils.pseudoRandom(point.x, point.y, 8) - 0.5) * 6.0;

          _elements.add(_ChalkElement(
            position: Offset(
              point.x + perpX * perpOff,
              point.y + perpY * perpOff,
            ),
            radius: 0.0, // not used for streaks
            opacity: (streakNoise * 0.3 * intensity).clamp(0.0, 1.0),
            color: baseColor,
            age: 0.0,
            lifetime: 0.9,
            type: _ChalkElementType.streak,
            streakEnd: Offset(
              point.x + perpX * perpOff - nx * (2 + streakNoise * 4),
              point.y + perpY * perpOff - ny * (2 + streakNoise * 4),
            ),
          ));
        }
      }
    }

    // ── Layer 4: Edge scatter (particles thrown outward from stroke edge) ──
    final scatterNoise = MathUtils.pseudoRandom(point.x, point.y, 9);
    if (scatterNoise > 0.7) {
      final angle = scatterNoise * math.pi * 2;
      final dist = 4.0 + scatterNoise * 8.0;
      _elements.add(_ChalkElement(
        position: Offset(
          point.x + math.cos(angle) * dist,
          point.y + math.sin(angle) * dist,
        ),
        radius: 0.3 + scatterNoise * 0.8,
        opacity: (scatterNoise * 0.25 * intensity).clamp(0.0, 1.0),
        color: baseColor,
        age: 0.0,
        lifetime: 0.7,
        type: _ChalkElementType.dot,
      ));
    }

    // ── Layer 5: Dust cloud (very faint, large radius, airborne feel) ─────
    final dustNoise = MathUtils.pseudoRandom(point.x, point.y, 10);
    if (dustNoise > 0.85) {
      final dustAngle = dustNoise * math.pi * 2;
      final dustDist = 6.0 + dustNoise * 14.0;
      _elements.add(_ChalkElement(
        position: Offset(
          point.x + math.cos(dustAngle) * dustDist,
          point.y + math.sin(dustAngle) * dustDist,
        ),
        radius: 3.0 + dustNoise * 5.0,
        opacity: (dustNoise * 0.08 * intensity).clamp(0.0, 1.0),
        color: baseColor,
        age: 0.0,
        lifetime: 1.5,
        type: _ChalkElementType.dust,
      ));
    }
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {}

  @override
  void update(double dt) {
    for (final e in _elements) {
      e.age += dt;
    }
    _elements.removeWhere((e) => e.age >= e.lifetime);
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final elem in _elements) {
      final t = (elem.age / elem.lifetime).clamp(0.0, 1.0);
      // Smooth ease-out fade
      final fadeCurve = (1.0 - t * t).clamp(0.0, 1.0);
      final opacity = (elem.opacity * fadeCurve).clamp(0.0, 1.0);
      if (opacity < 0.005) continue;

      switch (elem.type) {
        case _ChalkElementType.dot:
          final paint = Paint()
            ..color = elem.color.withOpacity(opacity)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(elem.position, elem.radius, paint);

        case _ChalkElementType.streak:
          final paint = Paint()
            ..color = elem.color.withOpacity(opacity)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            elem.position,
            elem.streakEnd ?? elem.position,
            paint,
          );

        case _ChalkElementType.dust:
          // Dust: larger, blurred soft circle
          final paint = Paint()
            ..color = elem.color.withOpacity(opacity)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(elem.position, elem.radius, paint);
      }
    }
  }

  @override
  void dispose() => _elements.clear();
}

enum _ChalkElementType { dot, streak, dust }

class _ChalkElement {
  _ChalkElement({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.color,
    required this.age,
    required this.lifetime,
    required this.type,
    this.streakEnd,
  });

  final Offset position;
  final double radius;
  final double opacity;
  final Color color;
  double age;
  final double lifetime;
  final _ChalkElementType type;
  final Offset? streakEnd;
}
