import 'package:flutter/gestures.dart';
import 'package:biscuitse/core/engine/stylus/stylus_adapter.dart';
import 'package:biscuitse/core/engine/stylus/stylus_detector.dart';

/// Handles stylus input from Android tablet pens.
///
/// Supports:
/// - **Samsung S Pen** — pressure, tilt, barrel button, Air Actions stub
/// - **USI pens** — standard pressure + tilt via standard pointer events
/// - **Wacom EMR pens** — high-resolution pressure, tilt, two barrel buttons
///
/// On Android, Flutter maps `MotionEvent` fields:
/// - `pressure` → [PointerEvent.pressure]
/// - `AXIS_TILT` → [PointerEvent.tilt]
/// - `AXIS_ORIENTATION` → [PointerEvent.orientation]
/// - Button mask → [PointerEvent.buttons]
///
/// Hover events before the pen touches are delivered as [PointerHoverEvent].
class AndroidStylusHandler {
  /// Creates a handler, optionally specifying the detected stylus type.
  AndroidStylusHandler({StylusType detectedType = StylusType.samsungSPen})
      : _adapter = AndroidStylusAdapter(detectedType: detectedType);

  final AndroidStylusAdapter _adapter;

  // ─── Input processing ─────────────────────────────────────────────────────

  /// Converts a touch [event] to [StylusInput].
  ///
  /// Returns `null` for events that are not from a stylus device.
  StylusInput? process(PointerEvent event) {
    if (!_adapter.accepts(event)) return null;
    return _adapter.convert(event);
  }

  /// Processes a hover event and returns a [StylusInput] with
  /// [StylusInput.hoverDistance] > 0.
  ///
  /// On Android, S Pen hover is reported via `PointerHoverEvent` before the
  /// pen touches the screen.  The distance is approximated from the pressure
  /// being 0 while the device kind is stylus.
  StylusInput? processHover(PointerHoverEvent event) {
    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      return null;
    }
    final base = _adapter.convert(event);
    // Mark as hovering: pressure is 0, distance is 1.0 (unknown exact mm).
    return StylusInput(
      position: base.position,
      pressure: 0.0,
      tiltX: base.tiltX,
      tiltY: base.tiltY,
      azimuth: base.azimuth,
      altitude: base.altitude,
      hoverDistance: 1.0,
      barrelButton1: base.barrelButton1,
      barrelButton2: base.barrelButton2,
      isEraser: base.isEraser,
      timestamp: base.timestamp,
      stylusType: base.stylusType,
    );
  }

  // ─── Barrel button helpers ────────────────────────────────────────────────

  /// Returns `true` if the primary barrel button is pressed in [input].
  static bool isPrimaryButtonPressed(StylusInput input) => input.barrelButton1;

  /// Returns `true` if the secondary barrel button is pressed in [input].
  static bool isSecondaryButtonPressed(StylusInput input) => input.barrelButton2;

  // ─── Tilt width multiplier ─────────────────────────────────────────────────

  /// Same tilt-to-width mapping as [ApplePencilHandler.tiltWidthMultiplier].
  static double tiltWidthMultiplier(StylusInput input) {
    const flat = 0.5236;   // 30°
    const normal = 1.0472; // 60°
    final alt = input.altitude;
    if (alt < flat) return 2.0;
    if (alt > normal) return 0.5;
    return 2.0 - 1.5 * ((alt - flat) / (normal - flat));
  }
}
