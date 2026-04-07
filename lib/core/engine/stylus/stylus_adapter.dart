import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';

/// Unified data model produced by any [StylusAdapter] implementation.
///
/// All physical quantities are normalised to platform-independent ranges so
/// the rendering engine never needs to know which platform produced the data.
class StylusInput {
  /// Creates a [StylusInput] with full stylus data.
  const StylusInput({
    required this.position,
    required this.pressure,
    required this.tiltX,
    required this.tiltY,
    required this.azimuth,
    required this.altitude,
    required this.hoverDistance,
    required this.barrelButton1,
    required this.barrelButton2,
    required this.isEraser,
    required this.timestamp,
    required this.stylusType,
  });

  /// Screen position in logical pixels.
  final Offset position;

  /// Normalised pressure in [0.0, 1.0].  1.0 = maximum press force.
  final double pressure;

  /// Tilt around the X axis in radians (−π/2 to +π/2).
  final double tiltX;

  /// Tilt around the Y axis in radians (−π/2 to +π/2).
  final double tiltY;

  /// Azimuth — pen rotation around its own axis, in radians [0, 2π).
  /// 0 = pointing towards the top of the screen.
  final double azimuth;

  /// Altitude — angle between pen and screen surface in radians.
  /// 0 = pen lying flat, π/2 = pen perpendicular to screen.
  final double altitude;

  /// Hover distance in logical pixels. 0.0 means pen is touching.
  /// Values > 0.0 indicate hovering above the surface.
  final double hoverDistance;

  /// `true` when the primary barrel button (S Pen / Wacom) is pressed.
  final bool barrelButton1;

  /// `true` when the secondary barrel button (Wacom) is pressed.
  final bool barrelButton2;

  /// `true` when the eraser end is active (invertedStylus) or the user has
  /// mapped a gesture to the eraser tool.
  final bool isEraser;

  /// Epoch milliseconds at the time this sample was captured.
  final int timestamp;

  /// Detected stylus type that produced this input.
  final StylusType stylusType;

  /// Whether the pen is currently hovering (not touching the surface).
  bool get isHovering => hoverDistance > 0.0 && pressure == 0.0;

  /// Constructs a zeroed [StylusInput] — useful as a default/placeholder.
  static const StylusInput zero = StylusInput(
    position: Offset.zero,
    pressure: 0.0,
    tiltX: 0.0,
    tiltY: 0.0,
    azimuth: 0.0,
    altitude: math.pi / 2,
    hoverDistance: 0.0,
    barrelButton1: false,
    barrelButton2: false,
    isEraser: false,
    timestamp: 0,
    stylusType: StylusType.unknown,
  );

  @override
  String toString() => 'StylusInput('
      'pos=$position, '
      'pressure=${pressure.toStringAsFixed(2)}, '
      'tilt=($tiltX, $tiltY), '
      'azimuth=${azimuth.toStringAsFixed(2)}, '
      'alt=${altitude.toStringAsFixed(2)}, '
      'hover=$hoverDistance, '
      'type=$stylusType)';
}

/// Abstract adapter that normalises platform-specific pointer events into a
/// unified [StylusInput].
///
/// Implementations:
/// - [ApplePencilAdapter] — iOS / iPadOS
/// - [AndroidStylusAdapter] — Android
/// - [GenericStylusAdapter] — fallback for all other platforms
///
/// Use [StylusAdapterFactory.forEvent] to automatically pick the right adapter.
abstract class StylusAdapter {
  /// Converts a Flutter [PointerEvent] into a normalised [StylusInput].
  ///
  /// Never throws — if data is unavailable, sensible defaults are used.
  StylusInput convert(PointerEvent event);

  /// Returns `true` if this adapter can handle the given event.
  bool accepts(PointerEvent event);
}

// ─── Apple Pencil Adapter ─────────────────────────────────────────────────────

/// Adapter for Apple Pencil on iOS / iPadOS.
///
/// Flutter's `PointerEvent` exposes:
/// - `pressure` — normalized force
/// - `tilt` — altitude angle (π/2 = perpendicular, 0 = flat)
/// - `orientation` — azimuth angle in radians
///
/// On iOS the `orientation` field carries the azimuth.  The altitude is
/// derived from `tilt` (which Flutter exposes as the complement of elevation).
class ApplePencilAdapter implements StylusAdapter {
  /// Creates an Apple Pencil adapter.
  ///
  /// [detectedType] allows the caller to pass a pre-detected [StylusType]
  /// (e.g. from the platform channel) rather than defaulting to [StylusType.applePencil2].
  const ApplePencilAdapter({
    this.detectedType = StylusType.applePencil2,
  });

  /// The specific Apple Pencil generation this adapter assumes.
  final StylusType detectedType;

  @override
  bool accepts(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus &&
      event.orientation != 0.0;

  @override
  StylusInput convert(PointerEvent event) {
    // On iOS, `event.orientation` is the azimuth in radians (−π to +π).
    // Normalise to [0, 2π).
    final azimuth = (event.orientation + 2 * math.pi) % (2 * math.pi);

    // `event.tilt` on iOS is the altitude angle (0 = horizontal, π/2 = vertical).
    final altitude = event.tilt.clamp(0.0, math.pi / 2);

    // Decompose altitude into tiltX/tiltY using azimuth.
    final tiltX = math.sin(altitude) * math.cos(azimuth);
    final tiltY = math.sin(altitude) * math.sin(azimuth);

    return StylusInput(
      position: event.localPosition,
      pressure: event.pressure.clamp(0.0, 1.0),
      tiltX: tiltX,
      tiltY: tiltY,
      azimuth: azimuth,
      altitude: altitude,
      hoverDistance: 0.0, // filled in by Pro-specific platform channel
      barrelButton1: false,
      barrelButton2: false,
      isEraser: event.kind == PointerDeviceKind.invertedStylus,
      timestamp: event.timeStamp.inMilliseconds,
      stylusType: detectedType,
    );
  }
}

// ─── Android Stylus Adapter ───────────────────────────────────────────────────

/// Adapter for Android stylus devices (S Pen, USI, Wacom EMR).
///
/// Android reports:
/// - `pressure` — raw float, normally [0, 1]
/// - `tilt` — altitude angle via `AXIS_TILT` (0 = flat, π/2 = upright)
/// - `orientation` — azimuth via `AXIS_ORIENTATION` (−π to +π)
/// - Hover is signalled by a separate `PointerHoverEvent` before touch.
class AndroidStylusAdapter implements StylusAdapter {
  /// Creates an Android stylus adapter.
  const AndroidStylusAdapter({
    this.detectedType = StylusType.samsungSPen,
  });

  /// The stylus type identified for this device.
  final StylusType detectedType;

  @override
  bool accepts(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;

  @override
  StylusInput convert(PointerEvent event) {
    final azimuth = (event.orientation + 2 * math.pi) % (2 * math.pi);
    final altitude = event.tilt.clamp(0.0, math.pi / 2);

    final tiltX = math.sin(altitude) * math.cos(azimuth);
    final tiltY = math.sin(altitude) * math.sin(azimuth);

    // Android button state is encoded in `event.buttons`.
    // Bit 0 = primary, bit 1 = secondary button.
    final buttons = event.buttons;
    final barrel1 = (buttons & 0x02) != 0;
    final barrel2 = (buttons & 0x04) != 0;

    return StylusInput(
      position: event.localPosition,
      pressure: event.pressure.clamp(0.0, 1.0),
      tiltX: tiltX,
      tiltY: tiltY,
      azimuth: azimuth,
      altitude: altitude,
      hoverDistance: 0.0,
      barrelButton1: barrel1,
      barrelButton2: barrel2,
      isEraser: event.kind == PointerDeviceKind.invertedStylus,
      timestamp: event.timeStamp.inMilliseconds,
      stylusType: detectedType,
    );
  }
}

// ─── Generic / Fallback Adapter ───────────────────────────────────────────────

/// Minimal adapter for any stylus not matched by platform-specific adapters.
///
/// Only extracts pressure; all angular data defaults to neutral values.
class GenericStylusAdapter implements StylusAdapter {
  /// Creates a generic stylus adapter.
  const GenericStylusAdapter();

  @override
  bool accepts(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus ||
      event.kind == PointerDeviceKind.touch;

  @override
  StylusInput convert(PointerEvent event) => StylusInput(
        position: event.localPosition,
        pressure: event.pressure.clamp(0.0, 1.0),
        tiltX: 0.0,
        tiltY: 0.0,
        azimuth: 0.0,
        altitude: math.pi / 2,
        hoverDistance: 0.0,
        barrelButton1: false,
        barrelButton2: false,
        isEraser: event.kind == PointerDeviceKind.invertedStylus,
        timestamp: event.timeStamp.inMilliseconds,
        stylusType: StylusType.generic,
      );
}

// ─── Factory ──────────────────────────────────────────────────────────────────

/// Selects the most appropriate [StylusAdapter] for a [PointerEvent].
///
/// The factory examines the event's kind and axis data and returns the most
/// specialised adapter available.  It is safe to call on every pointer event —
/// finger events simply use the [GenericStylusAdapter].
abstract final class StylusAdapterFactory {
  StylusAdapterFactory._();

  static final ApplePencilAdapter _apple = const ApplePencilAdapter();
  static final AndroidStylusAdapter _android = const AndroidStylusAdapter();
  static final GenericStylusAdapter _generic = const GenericStylusAdapter();

  /// Returns the best adapter for [event].
  static StylusAdapter forEvent(PointerEvent event) {
    if (_apple.accepts(event)) return _apple;
    if (_android.accepts(event)) return _android;
    return _generic;
  }

  /// Converts [event] directly into a [StylusInput] using the best adapter.
  static StylusInput convert(PointerEvent event) =>
      forEvent(event).convert(event);
}
