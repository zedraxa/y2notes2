import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Delete Animation Effect — satisfying dissolve when objects are deleted.
///
/// Full implementation in PR 7. Currently a structural stub.
class DeleteAnimationEffect implements WritingEffect {
  @override
  final String id = 'delete_animation';

  @override
  final String name = 'Delete Animation';

  @override
  final String description =
      'Deleted strokes and objects dissolve with a satisfying particle burst.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Trigger a deletion animation at [position].
  void triggerDelete(Offset position) {
    // TODO(PR-7): Implement deletion particle burst.
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
