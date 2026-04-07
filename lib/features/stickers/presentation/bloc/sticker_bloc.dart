import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_event.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_state.dart';

class StickerBloc extends Bloc<StickerEvent, StickerState> {
  StickerBloc() : super(const StickerState()) {
    on<StickerPlacementPending>(_onPlacementPending);
    on<StickerPlaced>(_onPlaced);
    on<StickerMoved>(_onMoved);
    on<StickerScaled>(_onScaled);
    on<StickerRotated>(_onRotated);
    on<StickerDeleted>(_onDeleted);
    on<StickerDuplicated>(_onDuplicated);
    on<StickerLayerChanged>(_onLayerChanged);
    on<StickerLocked>(_onLocked);
    on<StickerSelected>(_onSelected);
    on<StickerOpacityChanged>(_onOpacityChanged);
    on<StickerUndoRequested>(_onUndo);
    on<StickerRedoRequested>(_onRedo);
  }

  static const int _maxUndoStack = 50;

  List<StickerElement> _saveSnapshot(StickerState state) =>
      List<StickerElement>.from(state.stickers);

  StickerState _pushUndo(StickerState state) {
    final stack = [...state.undoStack, _saveSnapshot(state)];
    if (stack.length > _maxUndoStack) stack.removeAt(0);
    return state.copyWith(undoStack: stack, redoStack: []);
  }

  void _onPlacementPending(
      StickerPlacementPending event, Emitter<StickerState> emit) {
    emit(state.copyWith(pendingPlacement: event.template));
  }

  void _onPlaced(StickerPlaced event, Emitter<StickerState> emit) {
    final newState = _pushUndo(state);
    final stickers = [...newState.stickers, event.sticker];
    emit(newState.copyWith(
      stickers: stickers,
      selectedStickerId: event.sticker.id,
      pendingPlacement: null,
    ));
  }

  void _onMoved(StickerMoved event, Emitter<StickerState> emit) {
    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: newState.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(position: event.position);
        return s;
      }).toList(),
    ));
  }

  void _onScaled(StickerScaled event, Emitter<StickerState> emit) {
    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: newState.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(scale: event.scale);
        return s;
      }).toList(),
    ));
  }

  void _onRotated(StickerRotated event, Emitter<StickerState> emit) {
    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: newState.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(rotation: event.rotation);
        return s;
      }).toList(),
    ));
  }

  void _onDeleted(StickerDeleted event, Emitter<StickerState> emit) {
    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: newState.stickers.where((s) => s.id != event.id).toList(),
      selectedStickerId:
          state.selectedStickerId == event.id ? null : state.selectedStickerId,
    ));
  }

  void _onDuplicated(StickerDuplicated event, Emitter<StickerState> emit) {
    final matches = state.stickers.where((s) => s.id == event.id);
    if (matches.isEmpty) return;
    final original = matches.first;

    final duplicate = StickerElement(
      type: original.type,
      assetKey: original.assetKey,
      position: original.position + const Offset(20, 20),
      scale: original.scale,
      rotation: original.rotation,
      opacity: original.opacity,
      zIndex: original.zIndex + 1,
      isLocked: false,
      washiLength: original.washiLength,
      washiWidth: original.washiWidth,
      washiTint: original.washiTint,
    );
    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: [...newState.stickers, duplicate],
      selectedStickerId: duplicate.id,
    ));
  }

  void _onLayerChanged(StickerLayerChanged event, Emitter<StickerState> emit) {
    final idx = state.stickers.indexWhere((s) => s.id == event.id);
    if (idx < 0) return;
    final sticker = state.stickers[idx];
    final maxZ =
        state.stickers.fold(0, (m, s) => s.zIndex > m ? s.zIndex : m);
    final minZ =
        state.stickers.fold(0, (m, s) => s.zIndex < m ? s.zIndex : m);

    final int newZ;
    switch (event.direction) {
      case LayerDirection.front:
        newZ = maxZ + 1;
      case LayerDirection.back:
        newZ = minZ - 1;
      case LayerDirection.forward:
        newZ = sticker.zIndex + 1;
      case LayerDirection.backward:
        newZ = sticker.zIndex - 1;
    }

    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: newState.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(zIndex: newZ);
        return s;
      }).toList(),
    ));
  }

  void _onLocked(StickerLocked event, Emitter<StickerState> emit) {
    emit(state.copyWith(
      stickers: state.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(isLocked: event.isLocked);
        return s;
      }).toList(),
    ));
  }

  void _onSelected(StickerSelected event, Emitter<StickerState> emit) {
    emit(state.copyWith(selectedStickerId: event.id));
  }

  void _onOpacityChanged(
      StickerOpacityChanged event, Emitter<StickerState> emit) {
    final newState = _pushUndo(state);
    emit(newState.copyWith(
      stickers: newState.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(opacity: event.opacity);
        return s;
      }).toList(),
    ));
  }

  void _onUndo(StickerUndoRequested event, Emitter<StickerState> emit) {
    if (!state.canUndo) return;
    final stack = [...state.undoStack];
    final previous = stack.removeLast();
    final redoStack = [...state.redoStack, _saveSnapshot(state)];
    emit(state.copyWith(
      stickers: previous,
      undoStack: stack,
      redoStack: redoStack,
      selectedStickerId: null,
    ));
  }

  void _onRedo(StickerRedoRequested event, Emitter<StickerState> emit) {
    if (!state.canRedo) return;
    final redoStack = [...state.redoStack];
    final next = redoStack.removeLast();
    final undoStack = [...state.undoStack, _saveSnapshot(state)];
    emit(state.copyWith(
      stickers: next,
      undoStack: undoStack,
      redoStack: redoStack,
      selectedStickerId: null,
    ));
  }
}
