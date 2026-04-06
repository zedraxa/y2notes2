import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Drag Shadow Effect — elevated shadow while dragging an object.
///
/// Full implementation in PR 7. Currently a structural stub.
class DragShadowEffect implements WritingEffect {
  @override
  final String id = 'drag_shadow';

  @override
  final String name = 'Drag Shadow';

  @override
  final String description =
      'Objects cast a realistic shadow while being dragged, giving a '
      'sense of elevation.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Start rendering a drag shadow at [position] for [bounds].
  void startDrag(Offset position, Rect bounds) {
    // TODO(PR-7): Implement drag shadow rendering.
  }

  /// End the drag animation.
  void endDrag() {
    // TODO(PR-7): Animate shadow drop-down.
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
