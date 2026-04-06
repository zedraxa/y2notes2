import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Snap Glow Effect — brief glow when an object snaps to alignment.
///
/// Full implementation in PR 7. Currently a structural stub.
class SnapGlowEffect implements WritingEffect {
  @override
  final String id = 'snap_glow';

  @override
  final String name = 'Snap Glow';

  @override
  final String description =
      'A brief glow appears when a sticker or shape snaps to alignment.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Trigger a snap glow at [position].
  void trigger(Offset position) {
    // TODO(PR-7): Implement snap glow animation.
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
