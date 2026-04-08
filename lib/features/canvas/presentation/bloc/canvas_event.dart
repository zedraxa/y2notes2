import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:biscuits/core/engine/stylus/stylus_detector.dart';
import 'package:biscuits/core/engine/stylus/stylus_gesture_handler.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_element.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_type.dart';

/// Base class for all canvas events.
abstract class CanvasEvent extends Equatable {
  const CanvasEvent();
  @override
  List<Object?> get props => [];
}

/// User began a new stroke (pointer down).
class StrokeStarted extends CanvasEvent {
  const StrokeStarted(this.point);
  final PointData point;
  @override
  List<Object?> get props => [point];
}

/// User continued a stroke (pointer move).
class StrokeUpdated extends CanvasEvent {
  const StrokeUpdated(this.point);
  final PointData point;
  @override
  List<Object?> get props => [point];
}

/// User lifted the pen (pointer up / cancel).
class StrokeEnded extends CanvasEvent {
  const StrokeEnded();
}

/// Undo the last committed stroke.
class UndoRequested extends CanvasEvent {
  const UndoRequested();
}

/// Redo a previously undone stroke.
class RedoRequested extends CanvasEvent {
  const RedoRequested();
}

/// Change the active drawing tool.
class ToolChanged extends CanvasEvent {
  const ToolChanged(this.tool);
  final Tool tool;
  @override
  List<Object?> get props => [tool];
}

/// Change the active stroke colour.
class ColorChanged extends CanvasEvent {
  const ColorChanged(this.color);
  final Color color;
  @override
  List<Object?> get props => [color];
}

/// Change the active stroke base width.
class WidthChanged extends CanvasEvent {
  const WidthChanged(this.width);
  final double width;
  @override
  List<Object?> get props => [width];
}

/// Toggle all writing effects on/off.
class EffectsToggled extends CanvasEvent {
  const EffectsToggled({required this.enabled});
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

/// Update the canvas configuration (template, size, etc.).
class CanvasConfigUpdated extends CanvasEvent {
  const CanvasConfigUpdated(this.config);
  final CanvasConfig config;
  @override
  List<Object?> get props => [config];
}

/// Clear all strokes from the canvas.
class CanvasCleared extends CanvasEvent {
  const CanvasCleared();
}

/// Zoom/pan changed (from InteractiveViewer transformation).
class ViewportChanged extends CanvasEvent {
  const ViewportChanged({required this.zoom, required this.panOffset});
  final double zoom;
  final Offset panOffset;
  @override
  List<Object?> get props => [zoom, panOffset];
}

/// Change the active plugin-based drawing tool by ID.
class DrawingToolChanged extends CanvasEvent {
  const DrawingToolChanged(this.toolId);
  final String toolId;
  @override
  List<Object?> get props => [toolId];
}

/// Update the active tool's settings.
class ToolSettingsChanged extends CanvasEvent {
  const ToolSettingsChanged(this.settings);
  final ToolSettings settings;
  @override
  List<Object?> get props => [settings];
}

// ─── Shape events ─────────────────────────────────────────────────────────────

/// Add a new shape to the canvas (supports undo).
class ShapeAdded extends CanvasEvent {
  const ShapeAdded(this.shape);
  final ShapeElement shape;
  @override
  List<Object?> get props => [shape];
}

/// Update an existing shape (e.g. after moving/resizing).
class ShapeUpdated extends CanvasEvent {
  const ShapeUpdated(this.shape);
  final ShapeElement shape;
  @override
  List<Object?> get props => [shape];
}

/// Remove a shape permanently.
class ShapeDeleted extends CanvasEvent {
  const ShapeDeleted(this.shapeId);
  final String shapeId;
  @override
  List<Object?> get props => [shapeId];
}

/// Select a shape for editing.
class ShapeSelected extends CanvasEvent {
  const ShapeSelected(this.shapeId);
  final String shapeId;
  @override
  List<Object?> get props => [shapeId];
}

/// Deselect any selected shape.
class ShapeDeselected extends CanvasEvent {
  const ShapeDeselected();
}

/// Toggle auto-shape recognition on/off.
class AutoShapeRecognitionToggled extends CanvasEvent {
  const AutoShapeRecognitionToggled({required this.enabled});
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

/// User confirmed (accepted) the recognised shape proposal.
class ShapeRecognitionAccepted extends CanvasEvent {
  const ShapeRecognitionAccepted();
}

/// User rejected the recognised shape proposal.
class ShapeRecognitionRejected extends CanvasEvent {
  const ShapeRecognitionRejected();
}

/// Activate explicit shape-drawing mode with a pre-selected type.
class ShapeToolActivated extends CanvasEvent {
  const ShapeToolActivated(this.type);
  final ShapeType type;
  @override
  List<Object?> get props => [type];
}

/// Deactivate shape-drawing mode (return to freehand).
class ShapeToolDeactivated extends CanvasEvent {
  const ShapeToolDeactivated();
}

/// Snapshot the current shapes list onto the undo stack before a committed
/// shape mutation (add, delete, style/type change, or drag end).
///
/// Dispatched by [ShapeBloc] immediately before any destructive operation so
/// that [CanvasBloc] can record the pre-change state for undo.
class ShapeSnapshotRequested extends CanvasEvent {
  const ShapeSnapshotRequested();
}

// ─── Stylus events ────────────────────────────────────────────────────────────

/// Fired when a new stylus type is detected from an incoming [PointerEvent].
class StylusDetectedEvent extends CanvasEvent {
  const StylusDetectedEvent(this.stylusType);

  /// The detected stylus type.
  final StylusType stylusType;

  @override
  List<Object?> get props => [stylusType];
}

/// Fired when the pen enters or moves through hover range (not touching).
class HoverPositionChanged extends CanvasEvent {
  const HoverPositionChanged(
    this.position, {
    this.tilt = 0.0,
    this.azimuth = 0.0,
  });

  /// Hover position in canvas logical pixels.
  final Offset position;

  /// Altitude angle of the pen from the screen plane (0 = flat, π/2 = vertical).
  final double tilt;

  /// Azimuth angle of the pen in the screen plane (radians, 0 = pointing right).
  final double azimuth;

  @override
  List<Object?> get props => [position, tilt, azimuth];
}

/// Fired when the pen leaves hover range.
class HoverEnded extends CanvasEvent {
  const HoverEnded();
}

/// Fired when a stylus hardware gesture is translated to an [StylusGestureAction].
class StylusGestureTriggered extends CanvasEvent {
  const StylusGestureTriggered(this.action);

  /// The resolved action to execute.
  final StylusGestureAction action;

  @override
  List<Object?> get props => [action];
}
