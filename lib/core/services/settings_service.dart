import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Persists user preferences such as effect toggles and theme.
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

  // ─── Interaction-effect notifiers ─────────────────────────────────────────
  final Map<String, ValueNotifier<bool>> interactionEffectToggles = {};
  final Map<String, ValueNotifier<double>> interactionEffectIntensities = {};

  /// Master toggle for all interaction effects.
  final ValueNotifier<bool> interactionEffectsEnabledNotifier =
      ValueNotifier(true);

  // Key constants
  static const _darkModeKey = 'dark_mode';
  static const _effectsEnabledKey = 'effects_enabled';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _pageTemplateKey = 'page_template';
  static const _effectTogglePrefix = 'effect_toggle_';
  static const _effectIntensityPrefix = 'effect_intensity_';
  static const _interactionEffectsEnabledKey = 'interaction_effects_enabled';
  static const _interactionTogglePrefix = 'interaction_toggle_';
  static const _interactionIntensityPrefix = 'interaction_intensity_';

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

  // ─── Interaction effect setters / getters ──────────────────────────────────

  Future<void> setInteractionEffectsEnabled(bool value) async {
    interactionEffectsEnabledNotifier.value = value;
    await _prefs.setBool(_interactionEffectsEnabledKey, value);
  }

  Future<void> setInteractionEffectEnabled(String name, bool value) async {
    interactionEffectToggles[name]?.value = value;
    await _prefs.setBool('$_interactionTogglePrefix$name', value);
  }

  Future<void> setInteractionEffectIntensity(String name, double value) async {
    interactionEffectIntensities[name]?.value = value;
    await _prefs.setDouble('$_interactionIntensityPrefix$name', value);
  }

  bool isInteractionEffectEnabled(String name) =>
      interactionEffectToggles[name]?.value ?? true;
  double interactionEffectIntensity(String name) =>
      interactionEffectIntensities[name]?.value ?? 1.0;

  void dispose() {
    darkModeNotifier.dispose();
    effectsEnabledNotifier.dispose();
    hapticsEnabledNotifier.dispose();
    pageTemplateNotifier.dispose();
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
