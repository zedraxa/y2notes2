import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/viewport.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';

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
  }

  void _onUndo(UndoRequested event, Emitter<CanvasState> emit) {
    if (!state.canUndo) return;
    final strokes = List<Stroke>.of(state.strokes);
    final undone = strokes.removeLast();
    emit(state.copyWith(
      strokes: strokes,
      redoStack: [...state.redoStack, undone],
    ));
  }

  void _onRedo(RedoRequested event, Emitter<CanvasState> emit) {
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

  void _onColorChanged(ColorChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(activeColor: event.color));

  void _onWidthChanged(WidthChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(activeWidth: event.width));

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

  void _onDrawingToolChanged(DrawingToolChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(activeToolId: event.toolId));

  void _onToolSettingsChanged(ToolSettingsChanged event, Emitter<CanvasState> emit) =>
      emit(state.copyWith(activeToolSettings: event.settings));
}
