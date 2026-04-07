import 'package:flutter/gestures.dart';
import 'package:y2notes2/core/engine/stylus/stylus_adapter.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';

/// Processes Apple Pencil input events on iOS / iPadOS.
///
/// Responsibilities:
/// - Filters finger touches via palm rejection (only accepts stylus events).
/// - Extracts tilt, azimuth, and altitude from [PointerEvent] fields.
/// - Forwards platform-channel gesture events (double-tap, squeeze) when
///   available via [PencilChannel].
///
/// Usage:
/// ```dart
/// final handler = ApplePencilHandler();
/// final input = handler.process(pointerEvent);
/// if (input != null) {
///   // use input.pressure, input.tilt*, input.azimuth …
/// }
/// ```
class ApplePencilHandler {
  /// Creates an Apple Pencil handler, optionally overriding the detected type.
  ApplePencilHandler({StylusType detectedType = StylusType.applePencil2})
      : _adapter = ApplePencilAdapter(detectedType: detectedType);

  final ApplePencilAdapter _adapter;

  // ─── Palm rejection ───────────────────────────────────────────────────────

  /// Returns `true` when [event] should be treated as stylus input.
  ///
  /// On iOS, when a Pencil is paired, Flutter routes Pencil events with
  /// `kind == PointerDeviceKind.stylus`.  Finger events have
  /// `kind == PointerDeviceKind.touch`.  Palm rejection is handled natively by
  /// iPadOS but we guard here anyway to avoid double-processing.
  bool acceptsEvent(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;

  // ─── Input processing ─────────────────────────────────────────────────────

  /// Converts [event] to a [StylusInput] if the event comes from a stylus.
  ///
  /// Returns `null` for finger / mouse input — callers should fall back to
  /// their normal touch handling in that case.
  StylusInput? process(PointerEvent event) {
    if (!acceptsEvent(event)) return null;
    return _adapter.convert(event);
  }

  // ─── Tilt effects ─────────────────────────────────────────────────────────

  /// Computes the stroke-width multiplier from [input.altitude].
  ///
  /// | Altitude (pen angle) | Multiplier | Behaviour              |
  /// |----------------------|------------|------------------------|
  /// | < 30°                | 2.0        | Flat — shading mode    |
  /// | 30° – 60°            | 1.0        | Normal writing         |
  /// | > 60°                | 0.5        | Upright — fine detail  |
  static double tiltWidthMultiplier(StylusInput input) {
    const flat = 0.5236; // 30° in radians
    const normal = 1.0472; // 60° in radians

    final alt = input.altitude;
    if (alt < flat) return 2.0;
    if (alt > normal) return 0.5;
    final t = (alt - flat) / (normal - flat);
    return 2.0 - 1.5 * t;
  }

  // ─── Calligraphy edge angle ────────────────────────────────────────────────

  /// Returns the azimuth in radians, suitable for rotating a calligraphy brush
  /// tip to match the pen's physical orientation.
  ///
  /// When the stylus type does not support azimuth (e.g. gen-1 Pencil),
  /// returns 0.0 so the brush is not rotated.
  static double calligraphyAngle(StylusInput input) {
    if (!StylusDetector.hasCapability(input.stylusType, StylusCapability.azimuth)) {
      return 0.0;
    }
    return input.azimuth;
  }
}
