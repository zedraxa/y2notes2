import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:y2notes2/core/engine/stylus/pressure_curve.dart';
import 'package:y2notes2/core/engine/stylus/stylus_gesture_handler.dart';

/// Persists user preferences such as effect toggles, theme, and stylus settings.
class SettingsService {
  late SharedPreferences _prefs;

  // ─── Notifiers ────────────────────────────────────────────────────────────
  final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
  final ValueNotifier<bool> effectsEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> hapticsEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<String> pageTemplateNotifier = ValueNotifier('lined');

  // ─── Effect-specific notifiers ────────────────────────────────────────────
  final Map<String, ValueNotifier<bool>> effectToggles = {};
  final Map<String, ValueNotifier<double>> effectIntensities = {};

  // ─── Stylus notifiers ─────────────────────────────────────────────────────

  /// Selected pressure curve preset name, persisted across sessions.
  final ValueNotifier<String> pressureCurvePresetNotifier =
      ValueNotifier(PressureCurvePreset.soft.name);

  /// Tilt sensitivity multiplier [0.0, 2.0]. 1.0 = default.
  final ValueNotifier<double> tiltSensitivityNotifier = ValueNotifier(1.0);

  /// Whether hover preview (brush size circle before touch) is enabled.
  final ValueNotifier<bool> hoverPreviewEnabledNotifier = ValueNotifier(true);

  /// Whether palm rejection filtering is active.
  final ValueNotifier<bool> palmRejectionEnabledNotifier = ValueNotifier(true);

  /// Whether left-hand mode is active (mirrors hover cursor offset).
  final ValueNotifier<bool> leftHandModeNotifier = ValueNotifier(false);

  /// Gesture→action mappings, stored as a JSON string.
  final Map<String, ValueNotifier<String>> gestureMappings = {};

  // Key constants
  static const _darkModeKey = 'dark_mode';
  static const _effectsEnabledKey = 'effects_enabled';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _pageTemplateKey = 'page_template';
  static const _effectTogglePrefix = 'effect_toggle_';
  static const _effectIntensityPrefix = 'effect_intensity_';
  // Stylus keys
  static const _pressureCurveKey = 'stylus_pressure_curve';
  static const _tiltSensitivityKey = 'stylus_tilt_sensitivity';
  static const _hoverPreviewKey = 'stylus_hover_preview';
  static const _palmRejectionKey = 'stylus_palm_rejection';
  static const _leftHandModeKey = 'stylus_left_hand';
  static const _gestureMappingPrefix = 'stylus_gesture_';

  static const List<String> effectNames = [
    'ink_flow',
    'pressure_bloom',
    'ink_shimmer',
    'neon_glow',
    'watercolor_bleed',
    'fountain_pen',
    'ink_dry',
    'trail_particles',
    'rainbow_ink',
    'chalk',
  ];

  /// Initialize shared preferences and load persisted values.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    darkModeNotifier.value = _prefs.getBool(_darkModeKey) ?? false;
    effectsEnabledNotifier.value =
        _prefs.getBool(_effectsEnabledKey) ?? true;
    hapticsEnabledNotifier.value =
        _prefs.getBool(_hapticsEnabledKey) ?? true;
    pageTemplateNotifier.value =
        _prefs.getString(_pageTemplateKey) ?? 'lined';

    for (final name in effectNames) {
      effectToggles[name] = ValueNotifier(
        _prefs.getBool('$_effectTogglePrefix$name') ?? true,
      );
      effectIntensities[name] = ValueNotifier(
        _prefs.getDouble('$_effectIntensityPrefix$name') ?? 1.0,
      );
    }

    // Stylus settings
    pressureCurvePresetNotifier.value =
        _prefs.getString(_pressureCurveKey) ?? PressureCurvePreset.soft.name;
    tiltSensitivityNotifier.value =
        _prefs.getDouble(_tiltSensitivityKey) ?? 1.0;
    hoverPreviewEnabledNotifier.value =
        _prefs.getBool(_hoverPreviewKey) ?? true;
    palmRejectionEnabledNotifier.value =
        _prefs.getBool(_palmRejectionKey) ?? true;
    leftHandModeNotifier.value =
        _prefs.getBool(_leftHandModeKey) ?? false;

    for (final gesture in StylusGesture.values) {
      final key = '$_gestureMappingPrefix${gesture.name}';
      gestureMappings[gesture.name] = ValueNotifier(
        _prefs.getString(key) ?? _defaultGestureAction(gesture).name,
      );
    }
  }

  // ─── Setters ──────────────────────────────────────────────────────────────

  Future<void> setDarkMode(bool value) async {
    darkModeNotifier.value = value;
    await _prefs.setBool(_darkModeKey, value);
  }

  Future<void> setEffectsEnabled(bool value) async {
    effectsEnabledNotifier.value = value;
    await _prefs.setBool(_effectsEnabledKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabledNotifier.value = value;
    await _prefs.setBool(_hapticsEnabledKey, value);
  }

  Future<void> setPageTemplate(String template) async {
    pageTemplateNotifier.value = template;
    await _prefs.setString(_pageTemplateKey, template);
  }

  Future<void> setEffectEnabled(String name, bool value) async {
    effectToggles[name]?.value = value;
    await _prefs.setBool('$_effectTogglePrefix$name', value);
  }

  Future<void> setEffectIntensity(String name, double value) async {
    effectIntensities[name]?.value = value;
    await _prefs.setDouble('$_effectIntensityPrefix$name', value);
  }

  bool isEffectEnabled(String name) => effectToggles[name]?.value ?? true;
  double effectIntensity(String name) => effectIntensities[name]?.value ?? 1.0;

  // ─── Stylus setters ───────────────────────────────────────────────────────

  /// Persists the selected [PressureCurvePreset] by name.
  Future<void> setPressureCurvePreset(PressureCurvePreset preset) async {
    pressureCurvePresetNotifier.value = preset.name;
    await _prefs.setString(_pressureCurveKey, preset.name);
  }

  /// Returns the active [PressureCurve] based on persisted preset.
  PressureCurve get activePressureCurve {
    final presetName = pressureCurvePresetNotifier.value;
    final preset = PressureCurvePreset.values.firstWhere(
      (p) => p.name == presetName,
      orElse: () => PressureCurvePreset.soft,
    );
    return PressureCurve.fromPreset(preset);
  }

  /// Sets the tilt sensitivity multiplier.
  Future<void> setTiltSensitivity(double value) async {
    tiltSensitivityNotifier.value = value.clamp(0.0, 2.0);
    await _prefs.setDouble(_tiltSensitivityKey, tiltSensitivityNotifier.value);
  }

  /// Enables or disables the hover preview cursor.
  Future<void> setHoverPreviewEnabled(bool value) async {
    hoverPreviewEnabledNotifier.value = value;
    await _prefs.setBool(_hoverPreviewKey, value);
  }

  /// Enables or disables software palm rejection.
  Future<void> setPalmRejectionEnabled(bool value) async {
    palmRejectionEnabledNotifier.value = value;
    await _prefs.setBool(_palmRejectionKey, value);
  }

  /// Enables or disables left-hand mode.
  Future<void> setLeftHandMode(bool value) async {
    leftHandModeNotifier.value = value;
    await _prefs.setBool(_leftHandModeKey, value);
  }

  /// Persists a gesture→action mapping.
  Future<void> setGestureMapping(
      StylusGesture gesture, StylusGestureAction action) async {
    gestureMappings[gesture.name]?.value = action.name;
    final key = '$_gestureMappingPrefix${gesture.name}';
    await _prefs.setString(key, action.name);
  }

  /// Returns the persisted [StylusGestureAction] for [gesture].
  StylusGestureAction getGestureAction(StylusGesture gesture) {
    final actionName = gestureMappings[gesture.name]?.value ??
        _defaultGestureAction(gesture).name;
    return StylusGestureAction.values.firstWhere(
      (a) => a.name == actionName,
      orElse: () => _defaultGestureAction(gesture),
    );
  }

  static StylusGestureAction _defaultGestureAction(StylusGesture gesture) {
    switch (gesture) {
      case StylusGesture.barrelDoubleTap:
        return StylusGestureAction.switchToEraser;
      case StylusGesture.barrelButton:
        return StylusGestureAction.toggleEraser;
      case StylusGesture.squeeze:
        return StylusGestureAction.showToolPicker;
      case StylusGesture.barrelButton2:
        return StylusGestureAction.undo;
      default:
        return StylusGestureAction.none;
    }
  }

  void dispose() {
    darkModeNotifier.dispose();
    effectsEnabledNotifier.dispose();
    hapticsEnabledNotifier.dispose();
    pageTemplateNotifier.dispose();
    for (final n in effectToggles.values) {
      n.dispose();
    }
    for (final n in effectIntensities.values) {
      n.dispose();
    }
    pressureCurvePresetNotifier.dispose();
    tiltSensitivityNotifier.dispose();
    hoverPreviewEnabledNotifier.dispose();
    palmRejectionEnabledNotifier.dispose();
    leftHandModeNotifier.dispose();
    for (final n in gestureMappings.values) {
      n.dispose();
    }
  }
}
