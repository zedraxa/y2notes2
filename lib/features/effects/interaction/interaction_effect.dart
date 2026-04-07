import 'package:flutter/material.dart';

/// Common interface every interaction effect must implement.
///
/// Unlike [WritingEffect], interaction effects are not tied to stroke
/// lifecycle events. Instead each effect exposes typed trigger methods
/// relevant to its specific interaction type.
abstract class InteractionEffect {
  /// Unique machine-readable key (e.g. 'touch_ripple').
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

  /// Advance effect animations by [dt] seconds.
  void update(double dt);

  /// Draw the effect layer onto [canvas].
  void render(Canvas canvas, Size size);

  /// Clean up resources.
  void dispose();
}
