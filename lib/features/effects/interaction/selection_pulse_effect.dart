import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Selection Pulse Effect — pulsing highlight on selected objects.
///
/// Full implementation in PR 7. Currently a structural stub.
class SelectionPulseEffect implements WritingEffect {
  @override
  final String id = 'selection_pulse';

  @override
  final String name = 'Selection Pulse';

  @override
  final String description =
      'Selected objects gently pulse to indicate their active state.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Start pulsing the given [bounds].
  void startPulse(Rect bounds) {
    // TODO(PR-7): Implement selection pulse animation.
  }

  /// Stop pulsing.
  void stopPulse() {
    // TODO(PR-7): Stop animation.
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
