import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biscuits/core/engine/stylus/pressure_curve.dart';
import 'package:biscuits/core/engine/stylus/stylus_gesture_handler.dart';

/// Stylus hardware and gesture preferences.
class StylusSettings {
  StylusSettings(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _pressureCurveKey = 'stylus_pressure_curve';
  static const _tiltSensitivityKey = 'stylus_tilt_sensitivity';
  static const _hoverPreviewKey = 'stylus_hover_preview';
  static const _palmRejectionKey = 'stylus_palm_rejection';
  static const _leftHandModeKey = 'stylus_left_hand';
  static const _pencilOnlyModeKey = 'stylus_pencil_only';
  static const _ghostNibEnabledKey = 'stylus_ghost_nib';
  static const _gestureMappingPrefix = 'stylus_gesture_';

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<String> pressureCurvePresetNotifier =
      ValueNotifier(PressureCurvePreset.soft.name);
  final ValueNotifier<double> tiltSensitivityNotifier =
      ValueNotifier(1.0);
  final ValueNotifier<bool> hoverPreviewEnabledNotifier =
      ValueNotifier(true);
  final ValueNotifier<bool> palmRejectionEnabledNotifier =
      ValueNotifier(true);
  final ValueNotifier<bool> leftHandModeNotifier =
      ValueNotifier(false);
  final ValueNotifier<bool> pencilOnlyModeNotifier =
      ValueNotifier(false);
  final ValueNotifier<bool> ghostNibEnabledNotifier =
      ValueNotifier(true);
  final Map<String, ValueNotifier<String>> gestureMappings = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    pressureCurvePresetNotifier.value =
        _prefs.getString(_pressureCurveKey) ??
            PressureCurvePreset.soft.name;
    tiltSensitivityNotifier.value =
        _prefs.getDouble(_tiltSensitivityKey) ?? 1.0;
    hoverPreviewEnabledNotifier.value =
        _prefs.getBool(_hoverPreviewKey) ?? true;
    palmRejectionEnabledNotifier.value =
        _prefs.getBool(_palmRejectionKey) ?? true;
    leftHandModeNotifier.value =
        _prefs.getBool(_leftHandModeKey) ?? false;
    pencilOnlyModeNotifier.value =
        _prefs.getBool(_pencilOnlyModeKey) ?? false;
    ghostNibEnabledNotifier.value =
        _prefs.getBool(_ghostNibEnabledKey) ?? true;

    for (final gesture in StylusGesture.values) {
      final key = '$_gestureMappingPrefix${gesture.name}';
      gestureMappings[gesture.name] = ValueNotifier(
        _prefs.getString(key) ??
            _defaultGestureAction(gesture).name,
      );
    }
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setPressureCurvePreset(
    PressureCurvePreset preset,
  ) async {
    pressureCurvePresetNotifier.value = preset.name;
    await _prefs.setString(_pressureCurveKey, preset.name);
  }

  PressureCurve get activePressureCurve {
    final presetName = pressureCurvePresetNotifier.value;
    final preset = PressureCurvePreset.values.firstWhere(
      (p) => p.name == presetName,
      orElse: () => PressureCurvePreset.soft,
    );
    return PressureCurve.fromPreset(preset);
  }

  Future<void> setTiltSensitivity(double value) async {
    tiltSensitivityNotifier.value = value.clamp(0.0, 2.0);
    await _prefs.setDouble(
      _tiltSensitivityKey,
      tiltSensitivityNotifier.value,
    );
  }

  Future<void> setHoverPreviewEnabled(bool value) async {
    hoverPreviewEnabledNotifier.value = value;
    await _prefs.setBool(_hoverPreviewKey, value);
  }

  Future<void> setPalmRejectionEnabled(bool value) async {
    palmRejectionEnabledNotifier.value = value;
    await _prefs.setBool(_palmRejectionKey, value);
  }

  Future<void> setLeftHandMode(bool value) async {
    leftHandModeNotifier.value = value;
    await _prefs.setBool(_leftHandModeKey, value);
  }

  Future<void> setPencilOnlyMode(bool value) async {
    pencilOnlyModeNotifier.value = value;
    await _prefs.setBool(_pencilOnlyModeKey, value);
  }

  Future<void> setGhostNibEnabled(bool value) async {
    ghostNibEnabledNotifier.value = value;
    await _prefs.setBool(_ghostNibEnabledKey, value);
  }

  Future<void> setGestureMapping(
    StylusGesture gesture,
    StylusGestureAction action,
  ) async {
    gestureMappings[gesture.name]?.value = action.name;
    final key = '$_gestureMappingPrefix${gesture.name}';
    await _prefs.setString(key, action.name);
  }

  StylusGestureAction getGestureAction(StylusGesture gesture) {
    final actionName = gestureMappings[gesture.name]?.value ??
        _defaultGestureAction(gesture).name;
    return StylusGestureAction.values.firstWhere(
      (a) => a.name == actionName,
      orElse: () => _defaultGestureAction(gesture),
    );
  }

  static StylusGestureAction _defaultGestureAction(
    StylusGesture gesture,
  ) {
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

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    await setPressureCurvePreset(PressureCurvePreset.soft);
    await setTiltSensitivity(1.0);
    await setHoverPreviewEnabled(true);
    await setPalmRejectionEnabled(true);
    await setLeftHandMode(false);
    await setPencilOnlyMode(false);
    await setGhostNibEnabled(true);
    for (final gesture in StylusGesture.values) {
      await setGestureMapping(
        gesture,
        _defaultGestureAction(gesture),
      );
    }
  }

  void dispose() {
    pressureCurvePresetNotifier.dispose();
    tiltSensitivityNotifier.dispose();
    hoverPreviewEnabledNotifier.dispose();
    palmRejectionEnabledNotifier.dispose();
    leftHandModeNotifier.dispose();
    pencilOnlyModeNotifier.dispose();
    ghostNibEnabledNotifier.dispose();
    for (final n in gestureMappings.values) {
      n.dispose();
    }
  }
}
