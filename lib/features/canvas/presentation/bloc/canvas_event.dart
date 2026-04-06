import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';

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
