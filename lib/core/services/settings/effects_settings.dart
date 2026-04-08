import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writing-effect and interaction-effect preferences.
class EffectsSettings {
  EffectsSettings(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _effectsEnabledKey = 'effects_enabled';
  static const _effectTogglePrefix = 'effect_toggle_';
  static const _effectIntensityPrefix = 'effect_intensity_';
  static const _interactionEffectsEnabledKey =
      'interaction_effects_enabled';
  static const _interactionTogglePrefix = 'interaction_toggle_';
  static const _interactionIntensityPrefix = 'interaction_intensity_';

  // ── Effect catalogue ──────────────────────────────────────────────────────
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

  static const List<String> interactionEffectNames = [
    'touch_ripple',
    'snap_glow',
    'selection_pulse',
    'delete_animation',
    'drag_shadow',
    'pinch_zoom',
    'page_turn',
    'undo_redo',
    'tool_switch',
    'edge_bounce',
  ];

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<bool> effectsEnabledNotifier =
      ValueNotifier(true);
  final Map<String, ValueNotifier<bool>> effectToggles = {};
  final Map<String, ValueNotifier<double>> effectIntensities = {};

  final ValueNotifier<bool> interactionEffectsEnabledNotifier =
      ValueNotifier(true);
  final Map<String, ValueNotifier<bool>> interactionEffectToggles = {};
  final Map<String, ValueNotifier<double>>
      interactionEffectIntensities = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    effectsEnabledNotifier.value =
        _prefs.getBool(_effectsEnabledKey) ?? true;

    for (final name in effectNames) {
      effectToggles[name] = ValueNotifier(
        _prefs.getBool('$_effectTogglePrefix$name') ?? true,
      );
      effectIntensities[name] = ValueNotifier(
        _prefs.getDouble('$_effectIntensityPrefix$name') ?? 1.0,
      );
    }

    interactionEffectsEnabledNotifier.value =
        _prefs.getBool(_interactionEffectsEnabledKey) ?? true;

    for (final name in interactionEffectNames) {
      interactionEffectToggles[name] = ValueNotifier(
        _prefs.getBool('$_interactionTogglePrefix$name') ?? true,
      );
      interactionEffectIntensities[name] = ValueNotifier(
        _prefs.getDouble('$_interactionIntensityPrefix$name') ?? 1.0,
      );
    }
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setEffectsEnabled(bool value) async {
    effectsEnabledNotifier.value = value;
    await _prefs.setBool(_effectsEnabledKey, value);
  }

  Future<void> setEffectEnabled(String name, bool value) async {
    effectToggles[name]?.value = value;
    await _prefs.setBool('$_effectTogglePrefix$name', value);
  }

  Future<void> setEffectIntensity(
    String name,
    double value,
  ) async {
    effectIntensities[name]?.value = value;
    await _prefs.setDouble('$_effectIntensityPrefix$name', value);
  }

  bool isEffectEnabled(String name) =>
      effectToggles[name]?.value ?? true;
  double effectIntensity(String name) =>
      effectIntensities[name]?.value ?? 1.0;

  Future<void> setInteractionEffectsEnabled(bool value) async {
    interactionEffectsEnabledNotifier.value = value;
    await _prefs.setBool(_interactionEffectsEnabledKey, value);
  }

  Future<void> setInteractionEffectEnabled(
    String name,
    bool value,
  ) async {
    interactionEffectToggles[name]?.value = value;
    await _prefs.setBool('$_interactionTogglePrefix$name', value);
  }

  Future<void> setInteractionEffectIntensity(
    String name,
    double value,
  ) async {
    interactionEffectIntensities[name]?.value = value;
    await _prefs.setDouble(
      '$_interactionIntensityPrefix$name',
      value,
    );
  }

  bool isInteractionEffectEnabled(String name) =>
      interactionEffectToggles[name]?.value ?? true;
  double interactionEffectIntensity(String name) =>
      interactionEffectIntensities[name]?.value ?? 1.0;

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    await setEffectsEnabled(true);
    for (final name in effectNames) {
      await setEffectEnabled(name, true);
      await setEffectIntensity(name, 1.0);
    }
    await setInteractionEffectsEnabled(true);
    for (final name in interactionEffectNames) {
      await setInteractionEffectEnabled(name, true);
      await setInteractionEffectIntensity(name, 1.0);
    }
  }

  void dispose() {
    effectsEnabledNotifier.dispose();
    interactionEffectsEnabledNotifier.dispose();
    for (final n in effectToggles.values) {
      n.dispose();
    }
    for (final n in effectIntensities.values) {
      n.dispose();
    }
    for (final n in interactionEffectToggles.values) {
      n.dispose();
    }
    for (final n in interactionEffectIntensities.values) {
      n.dispose();
    }
  }
}
