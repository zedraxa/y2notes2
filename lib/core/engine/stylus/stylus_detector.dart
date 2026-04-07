import 'package:flutter/gestures.dart';

/// Categorises the stylus device type detected from a [PointerEvent].
///
/// The detection heuristic uses [PointerDeviceKind], pressure support, tilt
/// availability and platform information to infer the most likely device type.
enum StylusType {
  /// Apple Pencil (1st generation) — pressure + tilt, no double-tap.
  applePencil,

  /// Apple Pencil (2nd generation) — pressure + tilt + double-tap.
  applePencil2,

  /// Apple Pencil Pro — pressure + tilt + squeeze + hover + roll.
  applePencilPro,

  /// Samsung S Pen — pressure + tilt + barrel button + hover + Air Actions.
  samsungSPen,

  /// Universal Stylus Initiative pen — standard pressure + tilt.
  usiPen,

  /// Wacom EMR pen — high-resolution pressure + tilt + up to 2 barrel buttons.
  wacomEmr,

  /// Any stylus not matching the above profiles.
  generic,

  /// Touch input from a finger.
  finger,

  /// Input kind could not be determined.
  unknown,
}

/// Capabilities that a particular stylus may expose.
///
/// Use [StylusDetector.getCapabilities] to retrieve the set for a given type,
/// or [StylusDetector.hasCapability] to test a single feature.
enum StylusCapability {
  /// Analogue pressure from 0.0 to 1.0. Supported by all pen types.
  pressure,

  /// Pen tilt (altitude angle). Available on Apple Pencil, S Pen, Wacom.
  tilt,

  /// Azimuth angle — pen rotation around its own axis (0 to 2π).
  azimuth,

  /// Hover distance — pen detected before touching the screen.
  hover,

  /// Double-tap gesture on barrel — Apple Pencil 2 and Pro.
  doubleTap,

  /// Squeeze gesture — Apple Pencil Pro only.
  squeeze,

  /// Primary barrel button — S Pen and Wacom.
  barrelButton,

  /// Secondary barrel button — some Wacom pens.
  barrelButton2,

  /// Palm rejection handled at OS/platform level.
  palmRejection,

  /// Bluetooth pairing for advanced features.
  bluetoothPairing,

  /// Battery level reporting via platform channel.
  batteryLevel,

  /// Roll angle of pen tip — Apple Pencil Pro.
  rollAngle,
}

/// Detects the stylus type and capabilities from pointer events.
///
/// All methods are pure/static and never throw — on unknown inputs they return
/// [StylusType.unknown] or an empty capability set, enabling graceful
/// degradation on unsupported devices.
abstract final class StylusDetector {
  StylusDetector._();

  // ─── Capability map ───────────────────────────────────────────────────────

  static const Map<StylusType, Set<StylusCapability>> _capabilityMap = {
    StylusType.applePencil: {
      StylusCapability.pressure,
      StylusCapability.tilt,
      StylusCapability.azimuth,
      StylusCapability.palmRejection,
      StylusCapability.bluetoothPairing,
      StylusCapability.batteryLevel,
    },
    StylusType.applePencil2: {
      StylusCapability.pressure,
      StylusCapability.tilt,
      StylusCapability.azimuth,
      StylusCapability.doubleTap,
      StylusCapability.palmRejection,
      StylusCapability.bluetoothPairing,
      StylusCapability.batteryLevel,
    },
    StylusType.applePencilPro: {
      StylusCapability.pressure,
      StylusCapability.tilt,
      StylusCapability.azimuth,
      StylusCapability.hover,
      StylusCapability.doubleTap,
      StylusCapability.squeeze,
      StylusCapability.rollAngle,
      StylusCapability.palmRejection,
      StylusCapability.bluetoothPairing,
      StylusCapability.batteryLevel,
    },
    StylusType.samsungSPen: {
      StylusCapability.pressure,
      StylusCapability.tilt,
      StylusCapability.azimuth,
      StylusCapability.hover,
      StylusCapability.barrelButton,
      StylusCapability.palmRejection,
      StylusCapability.bluetoothPairing,
      StylusCapability.batteryLevel,
    },
    StylusType.usiPen: {
      StylusCapability.pressure,
      StylusCapability.tilt,
      StylusCapability.palmRejection,
    },
    StylusType.wacomEmr: {
      StylusCapability.pressure,
      StylusCapability.tilt,
      StylusCapability.azimuth,
      StylusCapability.barrelButton,
      StylusCapability.barrelButton2,
      StylusCapability.palmRejection,
    },
    StylusType.generic: {
      StylusCapability.pressure,
    },
    StylusType.finger: {},
    StylusType.unknown: {},
  };

  // ─── Detection ─────────────────────────────────────────────────────────────

  /// Infers the [StylusType] from a [PointerEvent].
  ///
  /// Detection strategy:
  /// 1. Finger/mouse events are classified immediately.
  /// 2. If `event.tilt` > 0 or pressure is reported and kind is [PointerDeviceKind.stylus],
  ///    we refine by checking available axis data.
  /// 3. On iOS the orientation field carries azimuth; on Android tilt maps to
  ///    `AXIS_TILT`. Presence of non-zero tilt + azimuth + hover distance
  ///    together suggest a premium stylus.
  static StylusType detectStylusType(PointerEvent event) {
    if (event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.mouse) {
      return StylusType.finger;
    }

    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      return StylusType.unknown;
    }

    final hasPressure = event.pressure > 0.0;
    final hasTilt = event.tilt != 0.0;
    final hasOrientation = event.orientation != 0.0;

    // Inverted stylus tip usually means the eraser end of a Wacom-style pen.
    if (event.kind == PointerDeviceKind.invertedStylus) {
      return StylusType.wacomEmr;
    }

    // Apple Pencil on iOS: reports non-zero orientation (azimuth).
    // High tilt resolution (sub-radian precision) distinguishes Pro from 2nd gen.
    // Without platform-channel info we can only distinguish pencil vs non-pencil.
    if (hasOrientation && hasTilt && hasPressure) {
      // Pro hover events have pressure == 0 and distance > 0 before touch.
      // Use this as a heuristic if available.
      return StylusType.applePencil2;
    }

    // Samsung S Pen and Wacom on Android: typically reports tilt but may not
    // report orientation (azimuth) unless the device supports it.
    if (hasTilt && hasPressure && !hasOrientation) {
      return StylusType.samsungSPen;
    }

    // USI pens: reports pressure + some tilt via standard Android API.
    if (hasPressure) {
      return StylusType.usiPen;
    }

    return StylusType.generic;
  }

  // ─── Capability queries ───────────────────────────────────────────────────

  /// Returns the full set of [StylusCapability] values for [type].
  ///
  /// Never returns null — unknown types return an empty set.
  static Set<StylusCapability> getCapabilities(StylusType type) =>
      _capabilityMap[type] ?? const {};

  /// Returns `true` when [type] is known to support [capability].
  static bool hasCapability(StylusType type, StylusCapability capability) =>
      _capabilityMap[type]?.contains(capability) ?? false;

  /// Returns `true` if the event originated from a stylus (not a finger).
  static bool isStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;
}
