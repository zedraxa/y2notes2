import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/shape_element.dart';
import '../../domain/entities/shape_type.dart';

/// Base event class for the shape feature BLoC.
abstract class ShapeEvent extends Equatable {
  const ShapeEvent();
  @override
  List<Object?> get props => [];
}

/// User tapped/clicked to select a shape.
class ShapeTapped extends ShapeEvent {
  const ShapeTapped(this.shapeId);
  final String shapeId;
  @override
  List<Object?> get props => [shapeId];
}

/// User tapped the canvas background (deselect).
class ShapeDeselectedEvent extends ShapeEvent {
  const ShapeDeselectedEvent();
}

/// User started dragging a shape body.
class ShapeDragStarted extends ShapeEvent {
  const ShapeDragStarted({required this.shapeId, required this.startPoint});
  final String shapeId;
  final Offset startPoint;
  @override
  List<Object?> get props => [shapeId, startPoint];
}

/// User moved the drag pointer.
class ShapeDragUpdated extends ShapeEvent {
  const ShapeDragUpdated(this.currentPoint);
  final Offset currentPoint;
  @override
  List<Object?> get props => [currentPoint];
}

/// User released the drag.
class ShapeDragEnded extends ShapeEvent {
  const ShapeDragEnded();
}

/// User started dragging a resize handle.
class HandleDragStarted extends ShapeEvent {
  const HandleDragStarted({
    required this.shapeId,
    required this.handleIndex,
    required this.startPoint,
  });
  final String shapeId;
  final int handleIndex;
  final Offset startPoint;
  @override
  List<Object?> get props => [shapeId, handleIndex, startPoint];
}

/// Resize handle drag updated.
class HandleDragUpdated extends ShapeEvent {
  const HandleDragUpdated(this.currentPoint);
  final Offset currentPoint;
  @override
  List<Object?> get props => [currentPoint];
}

/// Resize handle drag ended.
class HandleDragEnded extends ShapeEvent {
  const HandleDragEnded();
}

/// Update visual style of the selected shape.
class ShapeStyleUpdated extends ShapeEvent {
  const ShapeStyleUpdated({
    this.strokeColor,
    this.fillColor,
    this.strokeWidth,
    this.cornerRadius,
    this.opacity,
    this.isFilled,
    this.fillPattern,
  });
  final Color? strokeColor;
  final Color? fillColor;
  final double? strokeWidth;
  final double? cornerRadius;
  final double? opacity;
  final bool? isFilled;
  final ShapeFillPattern? fillPattern;
  @override
  List<Object?> get props => [
        strokeColor,
        fillColor,
        strokeWidth,
        cornerRadius,
        opacity,
        isFilled,
        fillPattern,
      ];
}

/// Convert the selected shape to a different [ShapeType].
class ShapeTypeChanged extends ShapeEvent {
  const ShapeTypeChanged(this.type);
  final ShapeType type;
  @override
  List<Object?> get props => [type];
}

/// Delete the currently-selected shape.
class ShapeDeleteRequested extends ShapeEvent {
  const ShapeDeleteRequested();
}

/// Duplicate the currently-selected shape.
class ShapeDuplicateRequested extends ShapeEvent {
  const ShapeDuplicateRequested();
}
