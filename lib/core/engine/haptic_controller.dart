import 'package:flutter/services.dart';
import 'package:y2notes2/core/services/settings_service.dart';

/// Centralised haptic feedback controller.
///
/// All haptics in the app should go through this class so that the
/// global "haptics enabled" setting is respected.
class HapticController {
  HapticController._();

  static SettingsService? _settings;

  /// Bind the controller to a [SettingsService] instance.
  static void bind(SettingsService settings) => _settings = settings;

  static bool get _enabled => _settings?.hapticsEnabledNotifier.value ?? true;

  /// Light impact — used for toolbar icon taps, colour selection, etc.
  static Future<void> light() async {
    if (_enabled) await HapticFeedback.lightImpact();
  }

  /// Medium impact — used for tool switches, mode toggles.
  static Future<void> medium() async {
    if (_enabled) await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — used for deletion, critical actions.
  static Future<void> heavy() async {
    if (_enabled) await HapticFeedback.heavyImpact();
  }

  /// Selection click — used for list / option selection.
  static Future<void> selection() async {
    if (_enabled) await HapticFeedback.selectionClick();
  }

  /// Vibrate — used for snap-align confirmation.
  static Future<void> vibrate() async {
    if (_enabled) await HapticFeedback.vibrate();
  }
}
