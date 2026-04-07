import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tool.dart';

/// A single drawn stroke on the canvas.
class Stroke extends Equatable {
  Stroke({
    String? id,
    required this.points,
    required this.tool,
    required this.color,
    required this.baseWidth,
    this.effectData = const {},
    this.toolId,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final List<PointData> points;
  final StrokeTool tool;
  final Color color;
  final double baseWidth;

  /// Extensible metadata for effects (e.g., rainbow ink distances, dry timing).
  final Map<String, dynamic> effectData;

  /// Optional ID of the plugin-based DrawingTool used to render this stroke.
  final String? toolId;

  bool get isEmpty => points.isEmpty;
  bool get hasPoints => points.isNotEmpty;

  Stroke copyWith({
    List<PointData>? points,
    StrokeTool? tool,
    Color? color,
    double? baseWidth,
    Map<String, dynamic>? effectData,
    String? toolId,
  }) =>
      Stroke(
        id: id,
        points: points ?? this.points,
        tool: tool ?? this.tool,
        color: color ?? this.color,
        baseWidth: baseWidth ?? this.baseWidth,
        effectData: effectData ?? this.effectData,
        toolId: toolId ?? this.toolId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'tool': tool.name,
        'color': color.value,
        'baseWidth': baseWidth,
        'effectData': effectData,
        if (toolId != null) 'toolId': toolId,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        id: json['id'] as String,
        points: (json['points'] as List<dynamic>)
            .map((p) => PointData.fromJson(p as Map<String, dynamic>))
            .toList(),
        tool: StrokeTool.values.byName(json['tool'] as String),
        color: Color(json['color'] as int),
        baseWidth: (json['baseWidth'] as num).toDouble(),
        effectData: json['effectData'] as Map<String, dynamic>? ?? {},
        toolId: json['toolId'] as String?,
      );

  @override
  List<Object?> get props => [id, points, tool, color, baseWidth, effectData, toolId];
}
