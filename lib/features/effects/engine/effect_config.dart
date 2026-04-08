import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';

/// Common interface every writing effect must implement.
abstract class WritingEffect {
  /// Unique machine-readable key (e.g. 'ink_flow').
  String get id;

  /// Human-readable display name.
  String get name;

  /// Short description shown in the settings page.
  String get description;

  bool get isEnabled;
  set isEnabled(bool value);

  /// Intensity multiplier (0.0 – 2.0, default 1.0).
  double get intensity;
  set intensity(double value);

  /// Called when the user presses down and a new stroke begins.
  void onStrokeStart(PointData point);

  /// Called for every new point added to the active stroke.
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  );

  /// Called when the user lifts the pen and the stroke is committed.
  void onStrokeEnd(Stroke completedStroke);

  /// Advance effect animations by [dt] seconds.
  void update(double dt);

  /// Draw the effect layer onto [canvas].
  void render(Canvas canvas, Size size);

  /// Clean up resources.
  void dispose();
}
