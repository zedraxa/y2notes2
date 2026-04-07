import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ToolSettings extends Equatable {
  const ToolSettings({
    this.color = const Color(0xFF2D2D2D),
    this.size = 3.0,
    this.opacity = 1.0,
    this.pressureSensitivity = 0.8,
    this.tiltSensitivity = 0.5,
    this.custom = const {},
  });

  final Color color;
  final double size;
  final double opacity;
  final double pressureSensitivity;
  final double tiltSensitivity;
  final Map<String, dynamic> custom;

  ToolSettings copyWith({
    Color? color,
    double? size,
    double? opacity,
    double? pressureSensitivity,
    double? tiltSensitivity,
    Map<String, dynamic>? custom,
  }) =>
      ToolSettings(
        color: color ?? this.color,
        size: size ?? this.size,
        opacity: opacity ?? this.opacity,
        pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
        tiltSensitivity: tiltSensitivity ?? this.tiltSensitivity,
        custom: custom ?? this.custom,
      );

  @override
  List<Object?> get props => [color, size, opacity, pressureSensitivity, tiltSensitivity, custom];
}
