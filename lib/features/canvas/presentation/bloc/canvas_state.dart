import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' hide Viewport;
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/core/engine/stylus/stylus_detector.dart';
import 'package:biscuits/core/extensions/iterable_extensions.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/canvas/domain/entities/tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuits/features/canvas/domain/models/viewport.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_element.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_type.dart';
import 'package:biscuits/features/shapes/engine/shape_recognizer.dart';

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
    this.activeToolId = 'fountain_pen',
    this.activeToolSettings = const ToolSettings(),
    // ── Shape state ──────────────────────────────────────────────────────
    this.shapes = const [],
    this.shapeUndoStack = const [],
    this.shapeRedoStack = const [],
    this.selectedShapeId,
    this.autoShapeRecognition = false,
    this.shapeRecognitionProposal,
    this.activeShapeType,
    this.isShapeMode = false,
    // ── Stylus state ──────────────────────────────────────────────────────
    this.detectedStylusType = StylusType.unknown,
    this.hoverPosition,
    this.isHovering = false,
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

  /// ID of the active plugin-based DrawingTool.
  final String activeToolId;

  /// Settings for the active plugin-based DrawingTool.
  final ToolSettings activeToolSettings;

  // ── Shape state ──────────────────────────────────────────────────────────

  /// All shapes placed on the canvas.
  final List<ShapeElement> shapes;

  /// Shapes available for undo (populated before each committed mutation).
  final List<List<ShapeElement>> shapeUndoStack;

  /// Shapes available for redo (parallels stroke redo stack).
  final List<List<ShapeElement>> shapeRedoStack;

  /// ID of the currently selected shape (null = none selected).
  final String? selectedShapeId;

  /// Whether freehand strokes are automatically analysed for shapes.
  final bool autoShapeRecognition;

  /// Pending recognition result awaiting user accept/reject.
  final ShapeRecognitionResult? shapeRecognitionProposal;

  /// Active shape type when in explicit shape-drawing mode.
  final ShapeType? activeShapeType;

  /// Whether the canvas is in shape-drawing mode (vs freehand).
  final bool isShapeMode;

  // ── Stylus state ──────────────────────────────────────────────────────────

  /// The most recently detected stylus type (updated on each pointer event).
  final StylusType detectedStylusType;

  /// Current hover position in canvas logical pixels. `null` when not hovering.
  final Offset? hoverPosition;

  /// Whether the stylus is currently hovering above the screen (not touching).
  final bool isHovering;

  // ── Derived getters ──────────────────────────────────────────────────────

  /// Returns the active plugin-based DrawingTool if registered.
  DrawingTool? get activeDrawingTool => ToolRegistry.get(activeToolId);

  bool get canUndo => strokes.isNotEmpty || shapeUndoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty || shapeRedoStack.isNotEmpty;
  bool get isDrawing => activeStroke != null;

  /// The currently selected ShapeElement.
  ShapeElement? get selectedShape =>
      selectedShapeId != null
          ? shapes.where((s) => s.id == selectedShapeId).firstOrNull
          : null;

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
    String? activeToolId,
    ToolSettings? activeToolSettings,
    List<ShapeElement>? shapes,
    List<List<ShapeElement>>? shapeUndoStack,
    List<List<ShapeElement>>? shapeRedoStack,
    String? selectedShapeId,
    bool clearShapeSelection = false,
    bool? autoShapeRecognition,
    ShapeRecognitionResult? shapeRecognitionProposal,
    bool clearShapeProposal = false,
    ShapeType? activeShapeType,
    bool clearActiveShapeType = false,
    bool? isShapeMode,
    StylusType? detectedStylusType,
    Offset? hoverPosition,
    bool clearHoverPosition = false,
    bool? isHovering,
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
        activeToolId: activeToolId ?? this.activeToolId,
        activeToolSettings: activeToolSettings ?? this.activeToolSettings,
        shapes: shapes ?? this.shapes,
        shapeUndoStack: shapeUndoStack ?? this.shapeUndoStack,
        shapeRedoStack: shapeRedoStack ?? this.shapeRedoStack,
        selectedShapeId: clearShapeSelection
            ? null
            : (selectedShapeId ?? this.selectedShapeId),
        autoShapeRecognition:
            autoShapeRecognition ?? this.autoShapeRecognition,
        shapeRecognitionProposal: clearShapeProposal
            ? null
            : (shapeRecognitionProposal ?? this.shapeRecognitionProposal),
        activeShapeType: clearActiveShapeType
            ? null
            : (activeShapeType ?? this.activeShapeType),
        isShapeMode: isShapeMode ?? this.isShapeMode,
        detectedStylusType: detectedStylusType ?? this.detectedStylusType,
        hoverPosition:
            clearHoverPosition ? null : (hoverPosition ?? this.hoverPosition),
        isHovering: isHovering ?? this.isHovering,
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
        activeToolId,
        activeToolSettings,
        shapes,
        shapeUndoStack,
        shapeRedoStack,
        selectedShapeId,
        autoShapeRecognition,
        shapeRecognitionProposal,
        activeShapeType,
        isShapeMode,
        detectedStylusType,
        hoverPosition,
        isHovering,
      ];
}
