import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Visual styling for a single graph function plot.
class GraphStyle extends Equatable {
  const GraphStyle({
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.isDashed = false,
    this.showPoints = false,
    this.pointRadius = 3.0,
  });

  final Color color;
  final double strokeWidth;
  final bool isDashed;
  final bool showPoints;
  final double pointRadius;

  GraphStyle copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
    bool? showPoints,
    double? pointRadius,
  }) =>
      GraphStyle(
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        isDashed: isDashed ?? this.isDashed,
        showPoints: showPoints ?? this.showPoints,
        pointRadius: pointRadius ?? this.pointRadius,
      );

  Map<String, dynamic> toJson() => {
        'color': color.value,
        'strokeWidth': strokeWidth,
        'isDashed': isDashed,
        'showPoints': showPoints,
        'pointRadius': pointRadius,
      };

  factory GraphStyle.fromJson(Map<String, dynamic> json) => GraphStyle(
        color: Color(json['color'] as int),
        strokeWidth: (json['strokeWidth'] as num).toDouble(),
        isDashed: json['isDashed'] as bool? ?? false,
        showPoints: json['showPoints'] as bool? ?? false,
        pointRadius: (json['pointRadius'] as num?)?.toDouble() ?? 3.0,
      );

  @override
  List<Object?> get props => [color, strokeWidth, isDashed, showPoints, pointRadius];
}
