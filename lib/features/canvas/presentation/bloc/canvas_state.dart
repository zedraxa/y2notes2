import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/domain/models/viewport.dart';

/// Immutable snapshot of canvas state.
class CanvasState extends Equatable {
  const CanvasState({
    this.strokes = const [],
    this.redoStack = const [],
    this.activeStroke,
    this.activeTool = Tool.defaultFountainPen,
    this.activeColor = AppColors.textPrimary,
    this.activeWidth = 3.0,
    this.config = const CanvasConfig(),
    this.viewport = const Viewport(),
    this.effectsEnabled = true,
  });

  /// All committed strokes in order.
  final List<Stroke> strokes;

  /// Strokes available for redo.
  final List<Stroke> redoStack;

  /// Currently-drawing stroke (null when not drawing).
  final Stroke? activeStroke;

  final Tool activeTool;
  final Color activeColor;
  final double activeWidth;
  final CanvasConfig config;
  final Viewport viewport;
  final bool effectsEnabled;

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get isDrawing => activeStroke != null;

  CanvasState copyWith({
    List<Stroke>? strokes,
    List<Stroke>? redoStack,
    Stroke? activeStroke,
    bool clearActiveStroke = false,
    Tool? activeTool,
    Color? activeColor,
    double? activeWidth,
    CanvasConfig? config,
    Viewport? viewport,
    bool? effectsEnabled,
  }) =>
      CanvasState(
        strokes: strokes ?? this.strokes,
        redoStack: redoStack ?? this.redoStack,
        activeStroke:
            clearActiveStroke ? null : (activeStroke ?? this.activeStroke),
        activeTool: activeTool ?? this.activeTool,
        activeColor: activeColor ?? this.activeColor,
        activeWidth: activeWidth ?? this.activeWidth,
        config: config ?? this.config,
        viewport: viewport ?? this.viewport,
        effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      );

  @override
  List<Object?> get props => [
        strokes,
        redoStack,
        activeStroke,
        activeTool,
        activeColor,
        activeWidth,
        config,
        viewport,
        effectsEnabled,
      ];
}
