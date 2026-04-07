import 'dart:async';
import 'package:flutter/services.dart';
import 'package:biscuitse/core/engine/stylus/stylus_detector.dart';

/// Events fired via the Android pen platform channel.
class AndroidPenEvent {
  /// Creates an Android pen event.
  const AndroidPenEvent({
    required this.type,
    required this.timestamp,
    this.extraData,
  });

  /// The type of event (e.g. `'buttonDown'`, `'buttonUp'`, `'airGesture'`).
  final String type;

  /// Epoch milliseconds when the event occurred on the native side.
  final int timestamp;

  /// Any additional data forwarded by the native plugin (may be null).
  final Map<String, dynamic>? extraData;

  @override
  String toString() => 'AndroidPenEvent(type=$type, ts=$timestamp)';
}

/// Information about the connected Android stylus.
class AndroidPenInfo {
  /// Creates Android pen info.
  const AndroidPenInfo({
    required this.type,
    required this.isConnected,
    this.batteryLevel,
    this.pressureLevels,
  });

  /// The detected stylus type.
  final StylusType type;

  /// Whether the pen is detected as active.
  final bool isConnected;

  /// Battery level in percent [0–100], or `null` if unavailable.
  final int? batteryLevel;

  /// Number of discrete pressure levels supported (e.g. 1024, 2048, 4096).
  final int? pressureLevels;

  @override
  String toString() => 'AndroidPenInfo(type=$type, connected=$isConnected, '
      'battery=$batteryLevel%, levels=$pressureLevels)';
}

/// Dart-side stub for the `com.biscuitse/android_pen` platform method channel.
///
/// The native side (Kotlin `AndroidPenPlugin.kt`) listens for:
/// - Samsung S Pen barrel button events via `MotionEvent` button mask
/// - S Pen Air Action gestures (future)
/// - Wacom secondary barrel button
///
/// On non-Android platforms, or when no compatible pen is detected, all
/// methods gracefully return `null` / empty streams.
///
/// Native stub: `android/app/src/main/kotlin/.../AndroidPenPlugin.kt`
class AndroidPenChannel {
  AndroidPenChannel._();

  static const MethodChannel _methodChannel =
      MethodChannel('com.biscuitse/android_pen');
  static const EventChannel _buttonEventChannel =
      EventChannel('com.biscuitse/android_pen/buttons');

  static Stream<AndroidPenEvent>? _buttonStream;

  /// A broadcast stream of [AndroidPenEvent] items for button and gesture
  /// events forwarded by the native plugin.
  ///
  /// Never throws — if the native channel is not available the stream remains
  /// empty.
  static Stream<AndroidPenEvent> get buttonStream {
    _buttonStream ??= _buttonEventChannel
        .receiveBroadcastStream()
        .map(_parseEvent)
        .where((e) => e != null)
        .cast<AndroidPenEvent>()
        .handleError((_) {/* swallow channel errors on non-Android platforms */});
    return _buttonStream!;
  }

  /// Queries the native side for connected pen information.
  ///
  /// Returns `null` when not on Android or when no compatible pen is detected.
  static Future<AndroidPenInfo?> getPenInfo() async {
    try {
      final result =
          await _methodChannel.invokeMapMethod<String, dynamic>('getPenInfo');
      if (result == null) return null;
      return AndroidPenInfo(
        type: _parseStylusType(result['type'] as String? ?? ''),
        isConnected: result['connected'] as bool? ?? false,
        batteryLevel: result['battery'] as int?,
        pressureLevels: result['pressureLevels'] as int?,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  // ─── Parsing helpers ──────────────────────────────────────────────────────

  static AndroidPenEvent? _parseEvent(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return AndroidPenEvent(
      type: map['type'] as String? ?? 'unknown',
      timestamp: map['timestamp'] as int? ?? 0,
      extraData: map['extra'] as Map<String, dynamic>?,
    );
  }

  static StylusType _parseStylusType(String raw) {
    switch (raw) {
      case 'samsungSPen':
        return StylusType.samsungSPen;
      case 'usiPen':
        return StylusType.usiPen;
      case 'wacomEmr':
        return StylusType.wacomEmr;
      default:
        return StylusType.generic;
    }
  }
}
