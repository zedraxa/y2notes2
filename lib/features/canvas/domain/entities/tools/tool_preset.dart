import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class ToolPreset {
  const ToolPreset({
    required this.id,
    required this.name,
    required this.toolId,
    required this.settings,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String toolId;
  final ToolSettings settings;
  final bool isBuiltIn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'toolId': toolId,
        'isBuiltIn': isBuiltIn,
        'color': settings.color.value,
        'size': settings.size,
        'opacity': settings.opacity,
        'pressureSensitivity': settings.pressureSensitivity,
        'tiltSensitivity': settings.tiltSensitivity,
        'custom': settings.custom,
      };

  factory ToolPreset.fromJson(Map<String, dynamic> json) => ToolPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        toolId: json['toolId'] as String,
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
        settings: ToolSettings(
          color: Color(json['color'] as int),
          size: (json['size'] as num).toDouble(),
          opacity: (json['opacity'] as num).toDouble(),
          pressureSensitivity:
              (json['pressureSensitivity'] as num?)?.toDouble() ?? 0.8,
          tiltSensitivity:
              (json['tiltSensitivity'] as num?)?.toDouble() ?? 0.5,
          custom: Map<String, dynamic>.from(json['custom'] as Map? ?? {}),
        ),
      );
}

class ToolPresetManager {
  static final _idGenerator = const Uuid();
  static final Map<String, List<ToolPreset>> _presets = {};
  static SettingsService? _settingsService;

  /// Bind a [SettingsService] for persistence. Call once during app init.
  static void bind(SettingsService service) {
    _settingsService = service;
  }

  /// Load persisted presets for a specific tool from SharedPreferences.
  static void loadPresetsForTool(String toolId) {
    final json = _settingsService?.loadToolPresets(toolId);
    if (json == null) return;
    try {
      final list = jsonDecode(json) as List;
      final presets =
          list.map((e) => ToolPreset.fromJson(e as Map<String, dynamic>)).toList();
      _presets[toolId] = [
        ...(_presets[toolId]?.where((p) => p.isBuiltIn) ?? []),
        ...presets,
      ];
    } catch (_) {
      // Silently ignore corrupted data.
    }
  }

  static void registerBuiltIn(ToolPreset preset) {
    _presets.putIfAbsent(preset.toolId, () => []).add(preset);
  }

  static List<ToolPreset> getPresetsForTool(String toolId) {
    if (_presets[toolId] == null) {
      loadPresetsForTool(toolId);
    }
    return _presets[toolId] ?? [];
  }

  static void savePreset(String name, String toolId, ToolSettings settings) {
    final id = _idGenerator.v4();
    _presets.putIfAbsent(toolId, () => []).add(
          ToolPreset(id: id, name: name, toolId: toolId, settings: settings),
        );
    _persist(toolId);
  }

  static void deletePreset(String id) {
    for (final entry in _presets.entries) {
      if (entry.value.any((p) => p.id == id)) {
        entry.value.removeWhere((p) => p.id == id);
        _persist(entry.key);
        break;
      }
    }
  }

  /// Persists non-built-in presets for [toolId] to SharedPreferences.
  static Future<void> _persist(String toolId) async {
    final userPresets =
        (_presets[toolId] ?? []).where((p) => !p.isBuiltIn).toList();
    final json = jsonEncode(userPresets.map((p) => p.toJson()).toList());
    await _settingsService?.saveToolPresets(toolId, json);
  }
}
