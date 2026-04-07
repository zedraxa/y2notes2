import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';
import 'package:y2notes2/core/engine/stylus/stylus_gesture_handler.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/domain/models/viewport.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_element.dart';
import 'package:y2notes2/features/shapes/engine/shape_recognizer.dart';

/// BLoC that manages all canvas state transitions.
class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  CanvasBloc({required SettingsService settingsService})
      : _settings = settingsService,
        super(CanvasState(
          effectsEnabled: settingsService.effectsEnabledNotifier.value,
        )) {
    on<StrokeStarted>(_onStrokeStarted);
    on<StrokeUpdated>(_onStrokeUpdated);
    on<StrokeEnded>(_onStrokeEnded);
    on<UndoRequested>(_onUndo);
    on<RedoRequested>(_onRedo);
    on<ToolChanged>(_onToolChanged);
    on<ColorChanged>(_onColorChanged);
    on<WidthChanged>(_onWidthChanged);
    on<EffectsToggled>(_onEffectsToggled);
    on<CanvasConfigUpdated>(_onConfigUpdated);
    on<CanvasCleared>(_onCanvasCleared);
    on<ViewportChanged>(_onViewportChanged);
    on<DrawingToolChanged>(_onDrawingToolChanged);
    on<ToolSettingsChanged>(_onToolSettingsChanged);
    // Shape events
    on<ShapeAdded>(_onShapeAdded);
    on<ShapeUpdated>(_onShapeUpdated);
    on<ShapeDeleted>(_onShapeDeleted);
    on<ShapeSelected>(_onShapeSelected);
    on<ShapeDeselected>(_onShapeDeselected);
    on<AutoShapeRecognitionToggled>(_onAutoShapeRecognitionToggled);
    on<ShapeRecognitionAccepted>(_onShapeRecognitionAccepted);
    on<ShapeRecognitionRejected>(_onShapeRecognitionRejected);
    on<ShapeToolActivated>(_onShapeToolActivated);
    on<ShapeToolDeactivated>(_onShapeToolDeactivated);
    on<ShapeSnapshotRequested>(_onShapeSnapshotRequested);
    // Stylus events
    on<StylusDetectedEvent>(_onStylusDetected);
    on<HoverPositionChanged>(_onHoverPositionChanged);
    on<HoverEnded>(_onHoverEnded);
    on<StylusGestureTriggered>(_onStylusGestureTriggered);
  }

  final SettingsService _settings;
  final _uuid = const Uuid();

  void _onStrokeStarted(StrokeStarted event, Emitter<CanvasState> emit) {
    final stroke = Stroke(
      id: _uuid.v4(),
      points: [event.point],
      tool: state.activeTool.type,
      color: state.activeColor,
      baseWidth: state.activeWidth,
      toolId: state.activeToolId,
    );
    emit(state.copyWith(activeStroke: stroke, redoStack: []));
  }

  void _onStrokeUpdated(StrokeUpdated event, Emitter<CanvasState> emit) {
    final active = state.activeStroke;
    if (active == null) return;
    final updated = active.copyWith(
      points: [...active.points, event.point],
    );
    emit(state.copyWith(activeStroke: updated));
  }

  void _onStrokeEnded(StrokeEnded event, Emitter<CanvasState> emit) {
    final active = state.activeStroke;
    if (active == null || active.points.length < 2) {
      emit(state.copyWith(clearActiveStroke: true));
      return;
    }
    final committed = [...state.strokes, active];
    // Enforce undo history cap
    final capped = committed.length > AppConstants.maxUndoHistory
        ? committed.sublist(committed.length - AppConstants.maxUndoHistory)
        : committed;
    emit(state.copyWith(
      strokes: capped,
      clearActiveStroke: true,
    ));
    // Attempt shape recognition when enabled (pass stroke before it was cleared).
    _tryRecognizeStroke(active, emit);
  }

  void _onUndo(UndoRequested event, Emitter<CanvasState> emit) {
    // Shape undo takes priority over stroke undo (LIFO across both stacks).
    if (state.shapeUndoStack.isNotEmpty) {
      final prevShapes = state.shapeUndoStack.last;
      final newUndoStack = state.shapeUndoStack
          .sublist(0, state.shapeUndoStack.length - 1);
      emit(state.copyWith(
        shapes: prevShapes,
        shapeUndoStack: newUndoStack,
        shapeRedoStack: [...state.shapeRedoStack, state.shapes],
      ));
      return;
    }
    if (!state.canUndo) return;
    final strokes = List<Stroke>.of(state.strokes);
    final undone = strokes.removeLast();
    emit(state.copyWith(
      strokes: strokes,
      redoStack: [...state.redoStack, undone],
    ));
  }

  void _onRedo(RedoRequested event, Emitter<CanvasState> emit) {
    // Shape redo takes priority over stroke redo.
    if (state.shapeRedoStack.isNotEmpty) {
      final nextShapes = state.shapeRedoStack.last;
      final newRedoStack = state.shapeRedoStack
          .sublist(0, state.shapeRedoStack.length - 1);
      emit(state.copyWith(
        shapes: nextShapes,
        shapeRedoStack: newRedoStack,
        shapeUndoStack: [...state.shapeUndoStack, state.shapes],
      ));
      return;
    }
    if (!state.canRedo) return;
    final redoStack = List<Stroke>.of(state.redoStack);
    final restored = redoStack.removeLast();
    emit(state.copyWith(
      strokes: [...state.strokes, restored],
      redoStack: redoStack,
    ));
  }

  void _onToolChanged(ToolChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(activeTool: event.tool));

  void _onColorChanged(ColorChanged event, Emitter<CanvasState> emit) => emit(
        state.copyWith(
          activeColor: event.color,
          activeToolSettings:
              state.activeToolSettings.copyWith(color: event.color),
        ),
      );

  void _onWidthChanged(WidthChanged event, Emitter<CanvasState> emit) => emit(
        state.copyWith(
          activeWidth: event.width,
          activeToolSettings:
              state.activeToolSettings.copyWith(size: event.width),
        ),
      );

  void _onEffectsToggled(EffectsToggled event, Emitter<CanvasState> emit) {
    _settings.setEffectsEnabled(event.enabled);
    emit(state.copyWith(effectsEnabled: event.enabled));
  }

  void _onConfigUpdated(CanvasConfigUpdated event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(config: event.config));

  void _onCanvasCleared(CanvasCleared event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(strokes: [], redoStack: []));

  void _onViewportChanged(ViewportChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(
        viewport: Viewport(zoom: event.zoom, panOffset: event.panOffset),
      ));

  void _onDrawingToolChanged(DrawingToolChanged event, Emitter<CanvasState> emit) {
    final newTool = ToolRegistry.get(event.toolId);
    // When switching tools, load the new tool's default settings while
    // preserving the current color and size chosen by the user.
    final newSettings = newTool?.defaultSettings.copyWith(
          color: state.activeColor,
          size: state.activeWidth,
        ) ??
        state.activeToolSettings;
    emit(state.copyWith(
      activeToolId: event.toolId,
      activeToolSettings: newSettings,
    ));
  }

  void _onToolSettingsChanged(ToolSettingsChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(activeToolSettings: event.settings));

  // ─── Shape event handlers ────────────────────────────────────────────────

  void _onShapeAdded(ShapeAdded event, Emitter<CanvasState> emit) {
    final shapes = [...state.shapes, event.shape];
    emit(state.copyWith(shapes: shapes, shapeRedoStack: []));
  }

  void _onShapeUpdated(ShapeUpdated event, Emitter<CanvasState> emit) {
    final shapes = state.shapes
        .map((s) => s.id == event.shape.id ? event.shape : s)
        .toList();
    emit(state.copyWith(shapes: shapes));
  }

  void _onShapeDeleted(ShapeDeleted event, Emitter<CanvasState> emit) {
    final shapes =
        state.shapes.where((s) => s.id != event.shapeId).toList();
    final wasSelected = state.selectedShapeId == event.shapeId;
    emit(state.copyWith(
      shapes: shapes,
      clearShapeSelection: wasSelected,
    ));
  }

  /// Saves the current shapes list onto the undo stack.
  ///
  /// [ShapeBloc] dispatches this event immediately before any committed shape
  /// mutation (add, delete, drag end, style / type change).
  void _onShapeSnapshotRequested(
      ShapeSnapshotRequested event, Emitter<CanvasState> emit) {
    final capped = _cappedShapeStack([...state.shapeUndoStack, state.shapes]);
    emit(state.copyWith(
      shapeUndoStack: capped,
      shapeRedoStack: [], // clear redo on new operation
    ));
  }

  void _onShapeSelected(ShapeSelected event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(selectedShapeId: event.shapeId));

  void _onShapeDeselected(ShapeDeselected event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(clearShapeSelection: true));

  void _onAutoShapeRecognitionToggled(
      AutoShapeRecognitionToggled event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(autoShapeRecognition: event.enabled));

  /// Called after [_onStrokeEnded] — run recognition if enabled.
  void _tryRecognizeStroke(Stroke stroke, Emitter<CanvasState> emit) {
    if (!state.autoShapeRecognition) return;
    final result = ShapeRecognizer.recognize(stroke.points);
    if (result == null || result.confidence < ShapeRecognizer.autoConvertThreshold) return;
    emit(state.copyWith(shapeRecognitionProposal: result));
  }

  void _onShapeRecognitionAccepted(
      ShapeRecognitionAccepted event, Emitter<CanvasState> emit) {
    final proposal = state.shapeRecognitionProposal;
    if (proposal == null) return;

    final shape = ShapeRecognizer.toShapeElement(
      proposal,
      strokeColor: state.activeColor,
      strokeWidth: state.activeWidth,
    );

    // Remove the last committed stroke (the freehand that was recognised).
    final strokes = state.strokes.isEmpty
        ? state.strokes
        : state.strokes.sublist(0, state.strokes.length - 1);

    // Snapshot current shapes so the add can be undone.
    final cappedUndo = _cappedShapeStack([...state.shapeUndoStack, state.shapes]);

    emit(state.copyWith(
      shapes: [...state.shapes, shape],
      shapeUndoStack: cappedUndo,
      shapeRedoStack: [],
      strokes: strokes,
      clearShapeProposal: true,
    ));
  }

  void _onShapeRecognitionRejected(
      ShapeRecognitionRejected event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(clearShapeProposal: true));

  void _onShapeToolActivated(
      ShapeToolActivated event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(
        isShapeMode: true,
        activeShapeType: event.type,
      ));

  void _onShapeToolDeactivated(
      ShapeToolDeactivated event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(
        isShapeMode: false,
        clearActiveShapeType: true,
        clearShapeSelection: true,
      ));

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns [stack] with at most [AppConstants.maxUndoHistory] entries,
  /// dropping the oldest entries if the cap is exceeded.
  List<List<ShapeElement>> _cappedShapeStack(
      List<List<ShapeElement>> stack) {
    if (stack.length <= AppConstants.maxUndoHistory) return stack;
    return stack.sublist(stack.length - AppConstants.maxUndoHistory);
  }

  // ─── Stylus event handlers ────────────────────────────────────────────────

  void _onStylusDetected(
      StylusDetectedEvent event, Emitter<CanvasState> emit) {
    if (state.detectedStylusType != event.stylusType) {
      emit(state.copyWith(detectedStylusType: event.stylusType));
    }
  }

  void _onHoverPositionChanged(
      HoverPositionChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(
        hoverPosition: event.position,
        isHovering: true,
      ));

  void _onHoverEnded(HoverEnded event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(
        clearHoverPosition: true,
        isHovering: false,
      ));

  void _onStylusGestureTriggered(
      StylusGestureTriggered event, Emitter<CanvasState> emit) {
    switch (event.action) {
      case StylusGestureAction.switchToEraser:
        emit(state.copyWith(
          activeTool: Tool.defaultEraser,
          activeToolId: 'eraser',
        ));
      case StylusGestureAction.toggleEraser:
        final isEraser = state.activeTool.type == StrokeTool.eraser;
        if (isEraser) {
          emit(state.copyWith(activeTool: Tool.defaultFountainPen));
        } else {
          emit(state.copyWith(activeTool: Tool.defaultEraser));
        }
      case StylusGestureAction.undo:
        if (state.canUndo) _onUndo(const UndoRequested(), emit);
      case StylusGestureAction.redo:
        if (state.canRedo) _onRedo(const RedoRequested(), emit);
      case StylusGestureAction.none:
      case StylusGestureAction.switchToLastTool:
      case StylusGestureAction.showToolPicker:
      case StylusGestureAction.showColorPicker:
      case StylusGestureAction.toggleEffects:
      case StylusGestureAction.custom:
        // These actions require UI interaction; handled at the widget layer.
        break;
    }
  }
}
