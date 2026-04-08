import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default tool and tool-preset persistence preferences.
class ToolSettings {
  ToolSettings(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _defaultToolSizeKey = 'default_tool_size';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _toolPresetPrefix = 'tool_preset_';

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<double> defaultToolSizeNotifier =
      ValueNotifier(3.0);
  final ValueNotifier<bool> hapticsEnabledNotifier =
      ValueNotifier(true);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    defaultToolSizeNotifier.value =
        _prefs.getDouble(_defaultToolSizeKey) ?? 3.0;
    hapticsEnabledNotifier.value =
        _prefs.getBool(_hapticsEnabledKey) ?? true;
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setDefaultToolSize(double value) async {
    defaultToolSizeNotifier.value = value.clamp(0.5, 20.0);
    await _prefs.setDouble(
      _defaultToolSizeKey,
      defaultToolSizeNotifier.value,
    );
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabledNotifier.value = value;
    await _prefs.setBool(_hapticsEnabledKey, value);
  }

  /// Saves a JSON-encoded list of preset data for the given tool.
  Future<void> saveToolPresets(
    String toolId,
    String jsonString,
  ) async {
    await _prefs.setString(
      '$_toolPresetPrefix$toolId',
      jsonString,
    );
  }

  /// Loads the raw JSON string of presets for the given tool.
  String? loadToolPresets(String toolId) =>
      _prefs.getString('$_toolPresetPrefix$toolId');

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    await setDefaultToolSize(3.0);
    await setHapticsEnabled(true);
  }

  void dispose() {
    defaultToolSizeNotifier.dispose();
    hapticsEnabledNotifier.dispose();
  }
}
