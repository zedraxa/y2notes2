import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

abstract class DrawingTool {
  String get id;
  String get name;
  String get description;
  ToolCategory get category;
  IconData get icon;

  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings);
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings);
  Path buildStrokePath(List<PointData> points, ToolSettings settings);

  double getWidth(PointData point, ToolSettings settings);
  Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints);
  double getOpacity(PointData point, ToolSettings settings);
  BlendMode get blendMode;

  bool get hasTexture;
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings);

  List<ToolSettingDefinition> get settingsSchema;
  ToolSettings get defaultSettings;
}
