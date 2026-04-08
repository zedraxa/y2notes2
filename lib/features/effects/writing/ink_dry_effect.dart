import 'package:flutter/material.dart';
import 'package:biscuits/core/utils/math_utils.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/effects/engine/effect_config.dart';

/// Ink Dry Animation — strokes start vivid and transition to normal.
///
/// When a stroke completes, it renders at 120% saturation then interpolates
/// to the true colour over [AppConstants.inkDryDuration] ms.
class InkDryEffect implements WritingEffect {
  InkDryEffect();

  @override
  final String id = 'ink_dry';

  @override
  final String name = 'Ink Dry';

  @override
  final String description =
      'Fresh strokes appear slightly over-saturated, then settle into '
      'their true colour as the ink "dries".';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Maps stroke id → elapsed seconds since completion.
  final Map<String, _DryStroke> _dryStrokes = {};

  static const double _dryDurationSeconds = 0.5;

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
    _dryStrokes[completedStroke.id] = _DryStroke(
      stroke: completedStroke,
      elapsed: 0.0,
    );
  }

  @override
  void update(double dt) {
    final expired = <String>[];
    for (final entry in _dryStrokes.entries) {
      entry.value.elapsed += dt;
      if (entry.value.elapsed >= _dryDurationSeconds) {
        expired.add(entry.key);
      }
    }
    for (final id in expired) {
      _dryStrokes.remove(id);
    }
  }

  @override
  void render(Canvas canvas, Size size) {
    for (final ds in _dryStrokes.values) {
      _renderDryCover(canvas, ds);
    }
  }

  void _renderDryCover(Canvas canvas, _DryStroke ds) {
    final t = (ds.elapsed / _dryDurationSeconds).clamp(0.0, 1.0);
    // Extra saturation boost fades from 1.2 → 1.0
    final saturationFactor = MathUtils.lerp(1.2 * intensity, 1.0, t);
    final boostedColor =
        MathUtils.adjustSaturation(ds.stroke.color, saturationFactor);

    // Overlay the stroke with the oversaturated colour fading out
    final overlayOpacity = ((1.0 - t) * 0.35 * intensity).clamp(0.0, 1.0);
    if (overlayOpacity <= 0.01) return;

    final pts = ds.stroke.points;
    if (pts.isEmpty) return;

    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }

    final paint = Paint()
      ..color = boostedColor.withOpacity(overlayOpacity)
      ..strokeWidth = ds.stroke.baseWidth * 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  void dispose() => _dryStrokes.clear();
}

class _DryStroke {
  _DryStroke({required this.stroke, required this.elapsed});

  final Stroke stroke;
  double elapsed;
}
