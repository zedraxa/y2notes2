enum ToolSettingType { slider, toggle, colorPicker, dropdown }

class ToolSettingDefinition {
  const ToolSettingDefinition({
    required this.key,
    required this.label,
    required this.type,
    required this.defaultValue,
    this.min,
    this.max,
    this.options,
  });

  final String key;
  final String label;
  final ToolSettingType type;
  final dynamic defaultValue;
  final dynamic min;
  final dynamic max;
  final List<String>? options;
}
