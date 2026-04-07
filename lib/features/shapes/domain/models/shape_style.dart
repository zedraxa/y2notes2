import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../entities/shape_type.dart';

/// Visual style settings shared across shapes and the shape tool.
class ShapeStyle extends Equatable {
  const ShapeStyle({
    this.strokeColor = const Color(0xFF2D2D2D),
    this.fillColor = Colors.transparent,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.cornerRadius = 0.0,
    this.isFilled = false,
    this.fillPattern = ShapeFillPattern.solid,
  });

  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final double opacity;
  final double cornerRadius;
  final bool isFilled;
  final ShapeFillPattern fillPattern;

  ShapeStyle copyWith({
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    double? opacity,
    double? cornerRadius,
    bool? isFilled,
    ShapeFillPattern? fillPattern,
  }) =>
      ShapeStyle(
        strokeColor: strokeColor ?? this.strokeColor,
        fillColor: fillColor ?? this.fillColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        opacity: opacity ?? this.opacity,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        isFilled: isFilled ?? this.isFilled,
        fillPattern: fillPattern ?? this.fillPattern,
      );

  @override
  List<Object?> get props => [
        strokeColor,
        fillColor,
        strokeWidth,
        opacity,
        cornerRadius,
        isFilled,
        fillPattern,
      ];
}
