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
}

class ToolPresetManager {
  static final Map<String, List<ToolPreset>> _presets = {};

  static void registerBuiltIn(ToolPreset preset) {
    _presets.putIfAbsent(preset.toolId, () => []).add(preset);
  }

  static List<ToolPreset> getPresetsForTool(String toolId) =>
      _presets[toolId] ?? [];

  static void savePreset(String name, String toolId, ToolSettings settings) {
    final id = '${toolId}_${DateTime.now().millisecondsSinceEpoch}';
    _presets.putIfAbsent(toolId, () => []).add(
          ToolPreset(id: id, name: name, toolId: toolId, settings: settings),
        );
  }

  static void deletePreset(String id) {
    for (final list in _presets.values) {
      list.removeWhere((p) => p.id == id);
    }
  }
}
