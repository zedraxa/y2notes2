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

  // ─── Recognition notifiers ────────────────────────────────────────────────
  final ValueNotifier<String> recognitionLanguageNotifier =
      ValueNotifier('en-US');
  final ValueNotifier<bool> recognitionRealTimeNotifier = ValueNotifier(false);
  final ValueNotifier<double> recognitionConfidenceNotifier =
      ValueNotifier(0.3);

  // ─── Effect-specific notifiers ────────────────────────────────────────────
  final Map<String, ValueNotifier<bool>> effectToggles = {};
  final Map<String, ValueNotifier<double>> effectIntensities = {};

  // Key constants
  static const _darkModeKey = 'dark_mode';
  static const _effectsEnabledKey = 'effects_enabled';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _pageTemplateKey = 'page_template';
  static const _effectTogglePrefix = 'effect_toggle_';
  static const _effectIntensityPrefix = 'effect_intensity_';
  static const _recognitionLanguageKey = 'recognition_language';
  static const _recognitionRealTimeKey = 'recognition_real_time';
  static const _recognitionConfidenceKey = 'recognition_confidence';

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

    recognitionLanguageNotifier.value =
        _prefs.getString(_recognitionLanguageKey) ?? 'en-US';
    recognitionRealTimeNotifier.value =
        _prefs.getBool(_recognitionRealTimeKey) ?? false;
    recognitionConfidenceNotifier.value =
        _prefs.getDouble(_recognitionConfidenceKey) ?? 0.3;

    for (final name in effectNames) {
      effectToggles[name] = ValueNotifier(
        _prefs.getBool('$_effectTogglePrefix$name') ?? true,
      );
      effectIntensities[name] = ValueNotifier(
        _prefs.getDouble('$_effectIntensityPrefix$name') ?? 1.0,
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

  Future<void> setRecognitionLanguage(String code) async {
    recognitionLanguageNotifier.value = code;
    await _prefs.setString(_recognitionLanguageKey, code);
  }

  Future<void> setRecognitionRealTime(bool value) async {
    recognitionRealTimeNotifier.value = value;
    await _prefs.setBool(_recognitionRealTimeKey, value);
  }

  Future<void> setRecognitionConfidence(double value) async {
    recognitionConfidenceNotifier.value = value;
    await _prefs.setDouble(_recognitionConfidenceKey, value);
  }

  bool isEffectEnabled(String name) => effectToggles[name]?.value ?? true;
  double effectIntensity(String name) => effectIntensities[name]?.value ?? 1.0;

  void dispose() {
    darkModeNotifier.dispose();
    effectsEnabledNotifier.dispose();
    hapticsEnabledNotifier.dispose();
    pageTemplateNotifier.dispose();
    recognitionLanguageNotifier.dispose();
    recognitionRealTimeNotifier.dispose();
    recognitionConfidenceNotifier.dispose();
    for (final n in effectToggles.values) {
      n.dispose();
    }
    for (final n in effectIntensities.values) {
      n.dispose();
    }
  }
}
