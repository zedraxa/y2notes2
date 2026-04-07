import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';
import 'package:y2notes2/features/widgets/presentation/bloc/widget_event.dart';
import 'package:y2notes2/features/widgets/presentation/bloc/widget_state.dart';

class WidgetBloc extends Bloc<WidgetEvent, WidgetState> {
  WidgetBloc() : super(const WidgetState()) {
    on<WidgetsLoaded>(_onLoaded);
    on<WidgetAdded>(_onAdded);
    on<WidgetRemoved>(_onRemoved);
    on<WidgetUpdated>(_onUpdated);
    on<WidgetMoved>(_onMoved);
    on<WidgetResized>(_onResized);
    on<WidgetTapped>(_onTapped);
    on<WidgetLongPressed>(_onLongPressed);
    on<WidgetStateChanged>(_onStateChanged);
    on<WidgetDeselected>(_onDeselected);
    on<WidgetUndoRequested>(_onUndo);
    on<WidgetRedoRequested>(_onRedo);
  }

  static const int _maxUndoStack = 50;

  List<SmartWidget> _snapshot(WidgetState s) =>
      List<SmartWidget>.from(s.widgets);

  WidgetState _pushUndo(WidgetState s) {
    final stack = [...s.undoStack, _snapshot(s)];
    if (stack.length > _maxUndoStack) stack.removeAt(0);
    return s.copyWith(undoStack: stack, redoStack: []);
  }

  void _onLoaded(WidgetsLoaded event, Emitter<WidgetState> emit) {
    // No-op for now; ready for persistence loading.
  }

  void _onAdded(WidgetAdded event, Emitter<WidgetState> emit) {
    final s = _pushUndo(state);
    emit(s.copyWith(
      widgets: [...s.widgets, event.widget],
      selectedWidgetId: event.widget.id,
    ));
  }

  void _onRemoved(WidgetRemoved event, Emitter<WidgetState> emit) {
    final s = _pushUndo(state);
    emit(s.copyWith(
      widgets: s.widgets.where((w) => w.id != event.widgetId).toList(),
      selectedWidgetId:
          state.selectedWidgetId == event.widgetId
              ? null
              : state.selectedWidgetId,
    ));
  }

  void _onUpdated(WidgetUpdated event, Emitter<WidgetState> emit) {
    final s = _pushUndo(state);
    emit(s.copyWith(
      widgets: s.widgets.map((w) {
        if (w.id == event.widget.id) return event.widget;
        return w;
      }).toList(),
    ));
  }

  void _onMoved(WidgetMoved event, Emitter<WidgetState> emit) {
    emit(state.copyWith(
      widgets: state.widgets.map((w) {
        if (w.id == event.widgetId) {
          return w.copyWith(position: event.position);
        }
        return w;
      }).toList(),
    ));
  }

  void _onResized(WidgetResized event, Emitter<WidgetState> emit) {
    emit(state.copyWith(
      widgets: state.widgets.map((w) {
        if (w.id == event.widgetId) {
          return w.copyWith(size: event.size);
        }
        return w;
      }).toList(),
    ));
  }

  void _onTapped(WidgetTapped event, Emitter<WidgetState> emit) {
    emit(state.copyWith(selectedWidgetId: event.widgetId));
  }

  void _onLongPressed(WidgetLongPressed event, Emitter<WidgetState> emit) {
    emit(state.copyWith(selectedWidgetId: event.widgetId));
  }

  void _onStateChanged(WidgetStateChanged event, Emitter<WidgetState> emit) {
    emit(state.copyWith(
      widgets: state.widgets.map((w) {
        if (w.id == event.widgetId) {
          return w.copyWith(state: {...w.state, ...event.newState});
        }
        return w;
      }).toList(),
    ));
  }

  void _onDeselected(WidgetDeselected event, Emitter<WidgetState> emit) {
    emit(state.copyWith(selectedWidgetId: null));
  }

  void _onUndo(WidgetUndoRequested event, Emitter<WidgetState> emit) {
    if (!state.canUndo) return;
    final stack = [...state.undoStack];
    final prev = stack.removeLast();
    final redoStack = [...state.redoStack, _snapshot(state)];
    emit(state.copyWith(
      widgets: prev,
      undoStack: stack,
      redoStack: redoStack,
      selectedWidgetId: null,
    ));
  }

  void _onRedo(WidgetRedoRequested event, Emitter<WidgetState> emit) {
    if (!state.canRedo) return;
    final redoStack = [...state.redoStack];
    final next = redoStack.removeLast();
    final undoStack = [...state.undoStack, _snapshot(state)];
    emit(state.copyWith(
      widgets: next,
      undoStack: undoStack,
      redoStack: redoStack,
      selectedWidgetId: null,
    ));
  }
}
