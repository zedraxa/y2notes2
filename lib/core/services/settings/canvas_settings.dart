import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Canvas spacing, page template, and gesture preferences.
class CanvasSettings {
  CanvasSettings(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _pageTemplateKey = 'page_template';
  static const _lineSpacingKey = 'canvas_line_spacing';
  static const _gridSpacingKey = 'canvas_grid_spacing';
  static const _dotSpacingKey = 'canvas_dot_spacing';
  static const _showMarginKey = 'canvas_show_margin';
  static const _pageGesturesEnabledKey = 'page_gestures_enabled';
  static const _pageGestureHapticsKey =
      'page_gesture_haptics_enabled';

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<String> pageTemplateNotifier =
      ValueNotifier('lined');
  final ValueNotifier<double> lineSpacingNotifier =
      ValueNotifier(32.0);
  final ValueNotifier<double> gridSpacingNotifier =
      ValueNotifier(32.0);
  final ValueNotifier<double> dotSpacingNotifier =
      ValueNotifier(32.0);
  final ValueNotifier<bool> showMarginNotifier = ValueNotifier(true);
  final ValueNotifier<bool> pageGesturesEnabledNotifier =
      ValueNotifier(true);
  final ValueNotifier<bool> pageGestureHapticsEnabledNotifier =
      ValueNotifier(true);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    pageTemplateNotifier.value =
        _prefs.getString(_pageTemplateKey) ?? 'lined';
    lineSpacingNotifier.value =
        _prefs.getDouble(_lineSpacingKey) ?? 32.0;
    gridSpacingNotifier.value =
        _prefs.getDouble(_gridSpacingKey) ?? 32.0;
    dotSpacingNotifier.value =
        _prefs.getDouble(_dotSpacingKey) ?? 32.0;
    showMarginNotifier.value =
        _prefs.getBool(_showMarginKey) ?? true;
    pageGesturesEnabledNotifier.value =
        _prefs.getBool(_pageGesturesEnabledKey) ?? true;
    pageGestureHapticsEnabledNotifier.value =
        _prefs.getBool(_pageGestureHapticsKey) ?? true;
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setPageTemplate(String template) async {
    pageTemplateNotifier.value = template;
    await _prefs.setString(_pageTemplateKey, template);
  }

  Future<void> setLineSpacing(double value) async {
    lineSpacingNotifier.value = value.clamp(16.0, 64.0);
    await _prefs.setDouble(
      _lineSpacingKey,
      lineSpacingNotifier.value,
    );
  }

  Future<void> setGridSpacing(double value) async {
    gridSpacingNotifier.value = value.clamp(16.0, 64.0);
    await _prefs.setDouble(
      _gridSpacingKey,
      gridSpacingNotifier.value,
    );
  }

  Future<void> setDotSpacing(double value) async {
    dotSpacingNotifier.value = value.clamp(16.0, 64.0);
    await _prefs.setDouble(
      _dotSpacingKey,
      dotSpacingNotifier.value,
    );
  }

  Future<void> setShowMargin(bool value) async {
    showMarginNotifier.value = value;
    await _prefs.setBool(_showMarginKey, value);
  }

  Future<void> setPageGesturesEnabled(bool value) async {
    pageGesturesEnabledNotifier.value = value;
    await _prefs.setBool(_pageGesturesEnabledKey, value);
  }

  Future<void> setPageGestureHapticsEnabled(bool value) async {
    pageGestureHapticsEnabledNotifier.value = value;
    await _prefs.setBool(_pageGestureHapticsKey, value);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    await setPageTemplate('lined');
    await setLineSpacing(32.0);
    await setGridSpacing(32.0);
    await setDotSpacing(32.0);
    await setShowMargin(true);
    await setPageGesturesEnabled(true);
    await setPageGestureHapticsEnabled(true);
  }

  void dispose() {
    pageTemplateNotifier.dispose();
    lineSpacingNotifier.dispose();
    gridSpacingNotifier.dispose();
    dotSpacingNotifier.dispose();
    showMarginNotifier.dispose();
    pageGesturesEnabledNotifier.dispose();
    pageGestureHapticsEnabledNotifier.dispose();
  }
}
