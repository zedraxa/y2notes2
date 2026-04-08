import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'shape_type.dart';

/// Represents a geometric shape placed on the canvas.
class ShapeElement extends Equatable {
  const ShapeElement({
    required this.id,
    required this.type,
    required this.bounds,
    this.rotation = 0.0,
    this.fillColor = Colors.transparent,
    this.strokeColor = const Color(0xFF2D2D2D),
    this.strokeWidth = 2.0,
    this.cornerRadius = 0.0,
    this.opacity = 1.0,
    this.vertices = const [],
    this.isFilled = false,
    this.fillPattern = ShapeFillPattern.solid,
  });

  /// Create a new shape with a generated UUID.
  factory ShapeElement.create({
    required ShapeType type,
    required Rect bounds,
    double rotation = 0.0,
    Color fillColor = Colors.transparent,
    Color strokeColor = const Color(0xFF2D2D2D),
    double strokeWidth = 2.0,
    double cornerRadius = 0.0,
    double opacity = 1.0,
    List<Offset> vertices = const [],
    bool isFilled = false,
    ShapeFillPattern fillPattern = ShapeFillPattern.solid,
  }) {
    return ShapeElement(
      id: const Uuid().v4(),
      type: type,
      bounds: bounds,
      rotation: rotation,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      cornerRadius: cornerRadius,
      opacity: opacity,
      vertices: vertices,
      isFilled: isFilled,
      fillPattern: fillPattern,
    );
  }

  final String id;
  final ShapeType type;

  /// Axis-aligned bounding box (pre-rotation).
  final Rect bounds;

  /// Rotation in radians around the shape's center.
  final double rotation;

  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  /// Corner radius for rectangle/square shapes.
  final double cornerRadius;

  final double opacity;

  /// Explicit polygon vertices (for triangle, star, pentagon, hexagon, diamond).
  /// Coordinates are in local space relative to [bounds].
  final List<Offset> vertices;

  final bool isFilled;
  final ShapeFillPattern fillPattern;

  /// Center of the bounding box.
  Offset get center => bounds.center;

  ShapeElement copyWith({
    String? id,
    ShapeType? type,
    Rect? bounds,
    double? rotation,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
    double? cornerRadius,
    double? opacity,
    List<Offset>? vertices,
    bool? isFilled,
    ShapeFillPattern? fillPattern,
  }) =>
      ShapeElement(
        id: id ?? this.id,
        type: type ?? this.type,
        bounds: bounds ?? this.bounds,
        rotation: rotation ?? this.rotation,
        fillColor: fillColor ?? this.fillColor,
        strokeColor: strokeColor ?? this.strokeColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        opacity: opacity ?? this.opacity,
        vertices: vertices ?? this.vertices,
        isFilled: isFilled ?? this.isFilled,
        fillPattern: fillPattern ?? this.fillPattern,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'bounds': {
          'left': bounds.left,
          'top': bounds.top,
          'width': bounds.width,
          'height': bounds.height,
        },
        'rotation': rotation,
        'fillColor': fillColor.value,
        'strokeColor': strokeColor.value,
        'strokeWidth': strokeWidth,
        'cornerRadius': cornerRadius,
        'opacity': opacity,
        'vertices':
            vertices.map((v) => {'dx': v.dx, 'dy': v.dy}).toList(),
        'isFilled': isFilled,
        'fillPattern': fillPattern.name,
      };

  factory ShapeElement.fromJson(Map<String, dynamic> json) => ShapeElement(
        id: json['id'] as String,
        type: ShapeType.values.byName(json['type'] as String),
        bounds: Rect.fromLTWH(
          (json['bounds']['left'] as num).toDouble(),
          (json['bounds']['top'] as num).toDouble(),
          (json['bounds']['width'] as num).toDouble(),
          (json['bounds']['height'] as num).toDouble(),
        ),
        rotation: (json['rotation'] as num).toDouble(),
        fillColor: Color(json['fillColor'] as int),
        strokeColor: Color(json['strokeColor'] as int),
        strokeWidth: (json['strokeWidth'] as num).toDouble(),
        cornerRadius: (json['cornerRadius'] as num).toDouble(),
        opacity: (json['opacity'] as num).toDouble(),
        vertices: (json['vertices'] as List<dynamic>)
            .map((v) => Offset(
                  (v['dx'] as num).toDouble(),
                  (v['dy'] as num).toDouble(),
                ))
            .toList(),
        isFilled: json['isFilled'] as bool,
        fillPattern:
            ShapeFillPattern.values.byName(json['fillPattern'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        type,
        bounds,
        rotation,
        fillColor,
        strokeColor,
        strokeWidth,
        cornerRadius,
        opacity,
        vertices,
        isFilled,
        fillPattern,
      ];
}
