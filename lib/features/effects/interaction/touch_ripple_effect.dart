import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Touch Ripple Effect — ripple feedback at touch/tap position.
///
/// Full implementation in PR 7. Currently a structural stub.
class TouchRippleEffect implements WritingEffect {
  @override
  final String id = 'touch_ripple';

  @override
  final String name = 'Touch Ripple';

  @override
  final String description =
      'A subtle ripple radiates from where you touch the canvas.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Trigger a ripple at [position].
  void trigger(Offset position) {
    // TODO(PR-7): Implement ripple animation.
  }

  @override
  void onStrokeStart(PointData point) {}

  @override
  void onStrokePoint(PointData point, PointData? previous, Stroke s) {}

  @override
  void onStrokeEnd(Stroke completedStroke) {}

  @override
  void update(double dt) {}

  @override
  void render(Canvas canvas, Size size) {}

  @override
  void dispose() {}
}
