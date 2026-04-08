import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biscuits/core/engine/stylus/pressure_curve.dart';
import 'package:biscuits/core/engine/stylus/stylus_gesture_handler.dart';
import 'package:biscuits/core/services/settings/backup_settings.dart';
import 'package:biscuits/core/services/settings/canvas_settings.dart';
import 'package:biscuits/core/services/settings/effects_settings.dart';
import 'package:biscuits/core/services/settings/recognition_settings.dart';
import 'package:biscuits/core/services/settings/stylus_settings.dart';
import 'package:biscuits/core/services/settings/theme_settings.dart';
import 'package:biscuits/core/services/settings/tool_settings.dart';

/// Persists user preferences such as effect toggles, theme, and
/// stylus settings.
///
/// This is now a **facade** that delegates to focused sub-services.
/// The public API is kept unchanged so existing callers continue to
/// work without modification. New code should prefer injecting the
/// specific sub-service it needs (e.g. [ThemeSettings]) via the
/// [ServiceLocator].
class SettingsService {
  // ── Sub-services ──────────────────────────────────────────────────────────
  late final ThemeSettings theme;
  late final EffectsSettings effects;
  late final StylusSettings stylus;
  late final RecognitionSettings recognition;
  late final CanvasSettings canvas;
  late final BackupSettings backup;
  late final ToolSettings tools;

  // ── Legacy notifier delegates ──────────────────────────────────────────────
  // These getters keep every existing `settingsService.fooNotifier`
  // call working by pointing at the sub-service's notifier.

  ValueNotifier<bool> get darkModeNotifier => theme.darkModeNotifier;
  ValueNotifier<bool> get effectsEnabledNotifier =>
      effects.effectsEnabledNotifier;
  ValueNotifier<bool> get hapticsEnabledNotifier =>
      tools.hapticsEnabledNotifier;
  ValueNotifier<String> get pageTemplateNotifier =>
      canvas.pageTemplateNotifier;

  ValueNotifier<String> get recognitionLanguageNotifier =>
      recognition.languageNotifier;
  ValueNotifier<bool> get recognitionRealTimeNotifier =>
      recognition.realTimeNotifier;
  ValueNotifier<double> get recognitionConfidenceNotifier =>
      recognition.confidenceNotifier;

  Map<String, ValueNotifier<bool>> get effectToggles =>
      effects.effectToggles;
  Map<String, ValueNotifier<double>> get effectIntensities =>
      effects.effectIntensities;

  ValueNotifier<String> get pressureCurvePresetNotifier =>
      stylus.pressureCurvePresetNotifier;
  ValueNotifier<double> get tiltSensitivityNotifier =>
      stylus.tiltSensitivityNotifier;
  ValueNotifier<bool> get hoverPreviewEnabledNotifier =>
      stylus.hoverPreviewEnabledNotifier;
  ValueNotifier<bool> get palmRejectionEnabledNotifier =>
      stylus.palmRejectionEnabledNotifier;
  ValueNotifier<bool> get leftHandModeNotifier =>
      stylus.leftHandModeNotifier;
  ValueNotifier<bool> get pencilOnlyModeNotifier =>
      stylus.pencilOnlyModeNotifier;
  ValueNotifier<bool> get ghostNibEnabledNotifier =>
      stylus.ghostNibEnabledNotifier;
  Map<String, ValueNotifier<String>> get gestureMappings =>
      stylus.gestureMappings;

  Map<String, ValueNotifier<bool>> get interactionEffectToggles =>
      effects.interactionEffectToggles;
  Map<String, ValueNotifier<double>>
      get interactionEffectIntensities =>
          effects.interactionEffectIntensities;
  ValueNotifier<bool> get interactionEffectsEnabledNotifier =>
      effects.interactionEffectsEnabledNotifier;

  ValueNotifier<bool> get autoSaveEnabledNotifier =>
      backup.autoSaveEnabledNotifier;
  ValueNotifier<int> get autoSaveIntervalNotifier =>
      backup.autoSaveIntervalNotifier;
  ValueNotifier<String> get defaultExportFormatNotifier =>
      backup.defaultExportFormatNotifier;

  ValueNotifier<double> get defaultToolSizeNotifier =>
      tools.defaultToolSizeNotifier;
  ValueNotifier<bool> get pageGesturesEnabledNotifier =>
      canvas.pageGesturesEnabledNotifier;
  ValueNotifier<bool> get pageGestureHapticsEnabledNotifier =>
      canvas.pageGestureHapticsEnabledNotifier;

  ValueNotifier<double> get lineSpacingNotifier =>
      canvas.lineSpacingNotifier;
  ValueNotifier<double> get gridSpacingNotifier =>
      canvas.gridSpacingNotifier;
  ValueNotifier<double> get dotSpacingNotifier =>
      canvas.dotSpacingNotifier;
  ValueNotifier<bool> get showMarginNotifier =>
      canvas.showMarginNotifier;

  // ── Static catalogues (kept for backward compat) ──────────────────────────

  static List<String> get effectNames => EffectsSettings.effectNames;
  static List<String> get interactionEffectNames =>
      EffectsSettings.interactionEffectNames;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialize shared preferences and load persisted values.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    theme = ThemeSettings(prefs)..init();
    effects = EffectsSettings(prefs)..init();
    stylus = StylusSettings(prefs)..init();
    recognition = RecognitionSettings(prefs)..init();
    canvas = CanvasSettings(prefs)..init();
    backup = BackupSettings(prefs)..init();
    tools = ToolSettings(prefs)..init();
  }

  // ── Delegating setters (backward compatible) ──────────────────────────────

  Future<void> setDarkMode(bool value) => theme.setDarkMode(value);

  Future<void> setEffectsEnabled(bool value) =>
      effects.setEffectsEnabled(value);

  Future<void> setHapticsEnabled(bool value) =>
      tools.setHapticsEnabled(value);

  Future<void> setPageTemplate(String template) =>
      canvas.setPageTemplate(template);

  Future<void> setEffectEnabled(String name, bool value) =>
      effects.setEffectEnabled(name, value);

  Future<void> setEffectIntensity(String name, double value) =>
      effects.setEffectIntensity(name, value);

  Future<void> setRecognitionLanguage(String code) =>
      recognition.setLanguage(code);

  Future<void> setRecognitionRealTime(bool value) =>
      recognition.setRealTime(value);

  Future<void> setRecognitionConfidence(double value) =>
      recognition.setConfidence(value);

  bool isEffectEnabled(String name) =>
      effects.isEffectEnabled(name);
  double effectIntensity(String name) =>
      effects.effectIntensity(name);

  Future<void> setPressureCurvePreset(
    PressureCurvePreset preset,
  ) =>
      stylus.setPressureCurvePreset(preset);

  PressureCurve get activePressureCurve =>
      stylus.activePressureCurve;

  Future<void> setTiltSensitivity(double value) =>
      stylus.setTiltSensitivity(value);

  Future<void> setHoverPreviewEnabled(bool value) =>
      stylus.setHoverPreviewEnabled(value);

  Future<void> setPalmRejectionEnabled(bool value) =>
      stylus.setPalmRejectionEnabled(value);

  Future<void> setLeftHandMode(bool value) =>
      stylus.setLeftHandMode(value);

  Future<void> setPencilOnlyMode(bool value) =>
      stylus.setPencilOnlyMode(value);

  Future<void> setGhostNibEnabled(bool value) =>
      stylus.setGhostNibEnabled(value);

  Future<void> setGestureMapping(
    StylusGesture gesture,
    StylusGestureAction action,
  ) =>
      stylus.setGestureMapping(gesture, action);

  StylusGestureAction getGestureAction(StylusGesture gesture) =>
      stylus.getGestureAction(gesture);

  Future<void> setAutoSaveEnabled(bool value) =>
      backup.setAutoSaveEnabled(value);

  Future<void> setAutoSaveInterval(int seconds) =>
      backup.setAutoSaveInterval(seconds);

  Future<void> setDefaultExportFormat(String format) =>
      backup.setDefaultExportFormat(format);

  Future<void> setDefaultToolSize(double value) =>
      tools.setDefaultToolSize(value);

  Future<void> setPageGesturesEnabled(bool value) =>
      canvas.setPageGesturesEnabled(value);

  Future<void> setPageGestureHapticsEnabled(bool value) =>
      canvas.setPageGestureHapticsEnabled(value);

  Future<void> setInteractionEffectsEnabled(bool value) =>
      effects.setInteractionEffectsEnabled(value);

  Future<void> setInteractionEffectEnabled(
    String name,
    bool value,
  ) =>
      effects.setInteractionEffectEnabled(name, value);

  Future<void> setInteractionEffectIntensity(
    String name,
    double value,
  ) =>
      effects.setInteractionEffectIntensity(name, value);

  bool isInteractionEffectEnabled(String name) =>
      effects.isInteractionEffectEnabled(name);
  double interactionEffectIntensity(String name) =>
      effects.interactionEffectIntensity(name);

  Future<void> setLineSpacing(double value) =>
      canvas.setLineSpacing(value);
  Future<void> setGridSpacing(double value) =>
      canvas.setGridSpacing(value);
  Future<void> setDotSpacing(double value) =>
      canvas.setDotSpacing(value);
  Future<void> setShowMargin(bool value) =>
      canvas.setShowMargin(value);

  Future<void> saveToolPresets(
    String toolId,
    String jsonString,
  ) =>
      tools.saveToolPresets(toolId, jsonString);

  String? loadToolPresets(String toolId) =>
      tools.loadToolPresets(toolId);

  // ── Reset to defaults ─────────────────────────────────────────────────────

  /// Resets all persisted settings to their default values.
  ///
  /// This restores every preference (appearance, effects, stylus,
  /// canvas spacing, recognition, backup, and interaction effects)
  /// to the factory defaults. User notebooks and drawings are not
  /// affected.
  Future<void> resetAll() async {
    await theme.reset();
    await effects.reset();
    await stylus.reset();
    await recognition.reset();
    await canvas.reset();
    await backup.reset();
    await tools.reset();
  }

  void dispose() {
    theme.dispose();
    effects.dispose();
    stylus.dispose();
    recognition.dispose();
    canvas.dispose();
    backup.dispose();
    tools.dispose();
  }
}
