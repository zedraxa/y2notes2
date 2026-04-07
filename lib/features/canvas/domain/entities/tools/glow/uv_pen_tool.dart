import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class UvPenTool extends BaseFreehandTool {
  @override String get id => 'uv_pen';
  @override String get name => 'UV Pen';
  @override String get description => 'Invisible in normal, bright in UV mode';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.visibility_off;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final uvMode = (settings.custom['uvMode'] as bool?) ?? false;
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.3, smoothing: 0.5);

    if (uvMode) {
      canvas.drawPath(path, Paint()
        ..color = Color.fromARGB(230, c.red, c.green, c.blue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..blendMode = blendMode);
      final corePath = buildFreehandPath(points, settings.copyWith(size: settings.size * 0.6), thinning: 0.2, smoothing: 0.5);
      canvas.drawPath(corePath, Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill
        ..blendMode = blendMode);
    } else {
      canvas.drawPath(path, Paint()
        ..color = Color.fromARGB(13, c.red, c.green, c.blue)
        ..style = PaintingStyle.fill
        ..blendMode = blendMode);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'uvMode', label: 'UV Mode', type: ToolSettingType.toggle, defaultValue: false),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'uvMode': false});
}
