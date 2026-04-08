import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/core/utils/math_utils.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/effects/engine/effect_config.dart';

/// Fountain Pen Variation Effect — calligraphic width modulation.
///
/// Combines angle-based nib rotation with directional width scaling. Renders
/// a primary calligraphy stroke with a secondary shadow stroke offset along
/// the nib perpendicular for added depth. Ink thins at sharp turns.
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
  double _prevAngle = 0.0;

  /// Nib angle in radians — 45° default for classic calligraphy.
  static const double _nibAngle = math.pi / 4;

  @override
  void onStrokeStart(PointData point) {
    _lastPoint = point;
    _prevAngle = 0.0;
  }

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
    final dx = point.x - prev.x;
    final dy = point.y - prev.y;
    final segLength = math.sqrt(dx * dx + dy * dy);
    if (segLength < 0.5) return; // skip micro-segments

    // Segment angle relative to the nib
    final segAngle = math.atan2(dy, dx);
    final nibDelta = (segAngle - _nibAngle).abs() % math.pi;
    // Width scales based on angle to nib: perpendicular = wide, parallel = thin
    final angleFactor =
        MathUtils.lerp(0.5, 1.5, math.sin(nibDelta).clamp(0.0, 1.0));

    // Directional width: downward = bold, upward = thin
    final double dirScale;
    if (dy > 0) {
      dirScale = AppConstants.fountainDownScale * intensity;
    } else if (dy < 0) {
      dirScale = AppConstants.fountainUpScale / intensity.clamp(0.5, 2.0);
    } else {
      dirScale = 1.0;
    }

    // Turn-thinning: sharp angle changes reduce width
    final angleDiff = (segAngle - _prevAngle).abs();
    final turnFactor = angleDiff > 0.4 ? MathUtils.lerp(1.0, 0.6, (angleDiff / math.pi).clamp(0.0, 1.0)) : 1.0;

    final width =
        activeStroke.baseWidth * angleFactor * dirScale * turnFactor;

    // Perpendicular offset for shadow stroke
    final perpX = -math.sin(segAngle) * width * 0.15;
    final perpY = math.cos(segAngle) * width * 0.15;

    _segments.add(_CalligraphySegment(
      from: Offset(prev.x, prev.y),
      to: Offset(point.x, point.y),
      width: width,
      color: activeStroke.color,
      age: 0.0,
      lifetime: 1.0,
      shadowOffsetX: perpX,
      shadowOffsetY: perpY,
    ));

    _prevAngle = segAngle;
    _lastPoint = point;
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {
    _lastPoint = null;
    _prevAngle = 0.0;
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
      final fade = (1.0 - t * 0.8).clamp(0.0, 1.0);

      // Shadow stroke — offset along nib perpendicular for depth
      final shadowOpacity = (fade * 0.15).clamp(0.0, 1.0);
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(shadowOpacity)
        ..strokeWidth = seg.width * 1.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final shadowOffset = Offset(seg.shadowOffsetX, seg.shadowOffsetY);
      canvas.drawLine(
        seg.from + shadowOffset,
        seg.to + shadowOffset,
        shadowPaint,
      );

      // Primary calligraphy stroke
      final primaryOpacity = (fade * 0.4).clamp(0.0, 1.0);
      final primaryPaint = Paint()
        ..color = seg.color.withOpacity(primaryOpacity)
        ..strokeWidth = seg.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(seg.from, seg.to, primaryPaint);

      // Highlight stroke — thin bright edge on the opposite side of shadow
      final highlightOpacity = (fade * 0.08).clamp(0.0, 1.0);
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(highlightOpacity)
        ..strokeWidth = seg.width * 0.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        seg.from - shadowOffset * 0.5,
        seg.to - shadowOffset * 0.5,
        highlightPaint,
      );
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
    required this.shadowOffsetX,
    required this.shadowOffsetY,
  });

  final Offset from;
  final Offset to;
  final double width;
  final Color color;
  double age;
  final double lifetime;
  final double shadowOffsetX;
  final double shadowOffsetY;
}
