import 'dart:async';
import 'package:flutter/services.dart';
import 'package:biscuitse/core/engine/stylus/stylus_detector.dart';

/// Gesture types fired by the Apple Pencil hardware.
enum PencilGesture {
  /// Double-tap on the flat side of Apple Pencil 2 or Pro.
  doubleTap,

  /// Squeeze gesture on Apple Pencil Pro.
  squeeze,
}

/// Information about the connected Apple Pencil.
class PencilInfo {
  /// Creates pencil info.
  const PencilInfo({
    required this.type,
    required this.isConnected,
    this.batteryLevel,
  });

  /// The generation / model of the pencil.
  final StylusType type;

  /// Whether the pencil is currently paired and connected.
  final bool isConnected;

  /// Battery level in percent [0–100], or `null` if unavailable.
  final int? batteryLevel;

  @override
  String toString() =>
      'PencilInfo(type=$type, connected=$isConnected, battery=$batteryLevel%)';
}

/// Dart-side stub for the `com.biscuitse/pencil` platform method channel.
///
/// The native side (iOS `PencilPlugin.swift`) listens for:
/// - `UIPencilInteraction` double-tap (iOS 12.1+)
/// - Squeeze gesture (iOS 17.5+ / Apple Pencil Pro)
///
/// When not running on iOS or when no Pencil is connected, all calls
/// gracefully return `null` / empty streams — no exceptions are thrown.
///
/// Native stub: `ios/Runner/PencilPlugin.swift`
class PencilChannel {
  PencilChannel._();

  static const MethodChannel _methodChannel =
      MethodChannel('com.biscuitse/pencil');
  static const EventChannel _eventChannel =
      EventChannel('com.biscuitse/pencil/gestures');

  static Stream<PencilGesture>? _gestureStream;

  /// A broadcast stream of [PencilGesture] events fired by the hardware.
  ///
  /// Emits `doubleTap` or `squeeze` events as they occur.  If the native
  /// channel is not available (non-iOS platform, no Pencil paired) the stream
  /// simply never emits.
  static Stream<PencilGesture> get gestureStream {
    _gestureStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(_parseGesture)
        .where((g) => g != null)
        .cast<PencilGesture>()
        .handleError((_) {/* silently swallow channel-not-found errors */});
    return _gestureStream!;
  }

  /// Queries the native side for current Pencil status.
  ///
  /// Returns `null` when not on iOS or when the native plugin is not
  /// initialised.
  static Future<PencilInfo?> getPencilInfo() async {
    try {
      final result =
          await _methodChannel.invokeMapMethod<String, dynamic>('getPencilInfo');
      if (result == null) return null;
      return PencilInfo(
        type: _parseStylusType(result['type'] as String? ?? ''),
        isConnected: result['connected'] as bool? ?? false,
        batteryLevel: result['battery'] as int?,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  // ─── Parsing helpers ──────────────────────────────────────────────────────

  static PencilGesture? _parseGesture(dynamic raw) {
    if (raw == 'doubleTap') return PencilGesture.doubleTap;
    if (raw == 'squeeze') return PencilGesture.squeeze;
    return null;
  }

  static StylusType _parseStylusType(String raw) {
    switch (raw) {
      case 'applePencil':
        return StylusType.applePencil;
      case 'applePencil2':
        return StylusType.applePencil2;
      case 'applePencilPro':
        return StylusType.applePencilPro;
      default:
        return StylusType.unknown;
    }
  }
}
