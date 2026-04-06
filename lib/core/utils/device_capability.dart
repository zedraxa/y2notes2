import 'package:flutter/foundation.dart';

/// Device performance tier for effect budget scaling.
enum DeviceTier { high, medium, low }

/// Detects the device performance tier using simple heuristics.
abstract class DeviceCapability {
  DeviceCapability._();

  static DeviceTier? _cached;

  /// Returns the detected [DeviceTier].
  ///
  /// Heuristic:
  /// - Desktop / macOS / Windows / Linux → high
  /// - iOS (iPad/iPhone) → high (modern Apple Silicon)
  /// - Android → medium by default (vast device spread)
  /// - Web → low (no GPU acceleration guarantee)
  static DeviceTier detect() {
    if (_cached != null) return _cached!;
    DeviceTier tier;
    if (kIsWeb) {
      tier = DeviceTier.low;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
          tier = DeviceTier.high;
        case TargetPlatform.android:
          tier = DeviceTier.medium;
        case TargetPlatform.fuchsia:
          tier = DeviceTier.low;
      }
    }
    _cached = tier;
    return tier;
  }

  /// Whether the device supports blur/shadow effects.
  static bool get supportsBlur => detect() != DeviceTier.low;

  /// Reset cached tier (useful for testing).
  static void resetCache() => _cached = null;
}
