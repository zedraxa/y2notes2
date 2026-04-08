import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handwriting recognition preferences.
class RecognitionSettings {
  RecognitionSettings(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _languageKey = 'recognition_language';
  static const _realTimeKey = 'recognition_real_time';
  static const _confidenceKey = 'recognition_confidence';

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<String> languageNotifier =
      ValueNotifier('en-US');
  final ValueNotifier<bool> realTimeNotifier = ValueNotifier(false);
  final ValueNotifier<double> confidenceNotifier =
      ValueNotifier(0.3);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    languageNotifier.value =
        _prefs.getString(_languageKey) ?? 'en-US';
    realTimeNotifier.value =
        _prefs.getBool(_realTimeKey) ?? false;
    confidenceNotifier.value =
        _prefs.getDouble(_confidenceKey) ?? 0.3;
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setLanguage(String code) async {
    languageNotifier.value = code;
    await _prefs.setString(_languageKey, code);
  }

  Future<void> setRealTime(bool value) async {
    realTimeNotifier.value = value;
    await _prefs.setBool(_realTimeKey, value);
  }

  Future<void> setConfidence(double value) async {
    confidenceNotifier.value = value;
    await _prefs.setDouble(_confidenceKey, value);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    await setLanguage('en-US');
    await setRealTime(false);
    await setConfidence(0.3);
  }

  void dispose() {
    languageNotifier.dispose();
    realTimeNotifier.dispose();
    confidenceNotifier.dispose();
  }
}
