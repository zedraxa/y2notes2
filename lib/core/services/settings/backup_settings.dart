import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backup, auto-save, and export preferences.
class BackupSettings {
  BackupSettings(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _autoSaveEnabledKey = 'auto_save_enabled';
  static const _autoSaveIntervalKey = 'auto_save_interval';
  static const _defaultExportFormatKey = 'default_export_format';

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<bool> autoSaveEnabledNotifier =
      ValueNotifier(true);
  final ValueNotifier<int> autoSaveIntervalNotifier =
      ValueNotifier(30);
  final ValueNotifier<String> defaultExportFormatNotifier =
      ValueNotifier('pdf');

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    autoSaveEnabledNotifier.value =
        _prefs.getBool(_autoSaveEnabledKey) ?? true;
    autoSaveIntervalNotifier.value =
        _prefs.getInt(_autoSaveIntervalKey) ?? 30;
    defaultExportFormatNotifier.value =
        _prefs.getString(_defaultExportFormatKey) ?? 'pdf';
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setAutoSaveEnabled(bool value) async {
    autoSaveEnabledNotifier.value = value;
    await _prefs.setBool(_autoSaveEnabledKey, value);
  }

  Future<void> setAutoSaveInterval(int seconds) async {
    autoSaveIntervalNotifier.value = seconds.clamp(5, 120);
    await _prefs.setInt(
      _autoSaveIntervalKey,
      autoSaveIntervalNotifier.value,
    );
  }

  Future<void> setDefaultExportFormat(String format) async {
    defaultExportFormatNotifier.value = format;
    await _prefs.setString(_defaultExportFormatKey, format);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    await setAutoSaveEnabled(true);
    await setAutoSaveInterval(30);
    await setDefaultExportFormat('pdf');
  }

  void dispose() {
    autoSaveEnabledNotifier.dispose();
    autoSaveIntervalNotifier.dispose();
    defaultExportFormatNotifier.dispose();
  }
}
