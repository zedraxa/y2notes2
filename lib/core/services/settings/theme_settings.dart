import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appearance and theme preferences.
class ThemeSettings {
  ThemeSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _darkModeKey = 'dark_mode';

  final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

  void init() {
    darkModeNotifier.value = _prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    darkModeNotifier.value = value;
    await _prefs.setBool(_darkModeKey, value);
  }

  Future<void> reset() async {
    await setDarkMode(false);
  }

  void dispose() {
    darkModeNotifier.dispose();
  }
}
