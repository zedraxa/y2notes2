import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/core/extensions/iterable_extensions.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart' as canvas_event;
import '../../domain/entities/shape_element.dart';
import '../../engine/snap_guide_engine.dart';
import 'shape_event.dart';
import 'shape_state.dart';

/// BLoC that manages selection, dragging, and resizing of shapes.
///
/// [CanvasBloc] is the canonical store for all shapes (and handles undo/redo).
/// This BLoC handles the interactive editing experience and dispatches
/// mutations to [CanvasBloc] so they are reflected in the rendered canvas
/// and tracked in the undo history.
class ShapeBloc extends Bloc<ShapeEvent, ShapeState> {
  ShapeBloc({required CanvasBloc canvasBloc})
      : _canvasBloc = canvasBloc,
        super(const ShapeState()) {
    on<ShapeTapped>(_onTapped);
    on<ShapeDeselectedEvent>(_onDeselected);
    on<ShapeDragStarted>(_onDragStarted);
    on<ShapeDragUpdated>(_onDragUpdated);
    on<ShapeDragEnded>(_onDragEnded);
    on<HandleDragStarted>(_onHandleDragStarted);
    on<HandleDragUpdated>(_onHandleDragUpdated);
    on<HandleDragEnded>(_onHandleDragEnded);
    on<ShapeStyleUpdated>(_onStyleUpdated);
    on<ShapeTypeChanged>(_onTypeChanged);
    on<ShapeDeleteRequested>(_onDeleteRequested);
    on<ShapeDuplicateRequested>(_onDuplicateRequested);
  }

  final CanvasBloc _canvasBloc;
  final _uuid = const Uuid();

  // Drag tracking
  Offset? _dragStart;
  Rect? _dragStartBounds;
  ShapeElement? _dragShape; // snapshot of shape at drag start
  int? _activeHandleIndex;

  // ─── Event handlers ───────────────────────────────────────────────────────

  void _onTapped(ShapeTapped event, Emitter<ShapeState> emit) {
    emit(state.copyWith(selectedShapeId: event.shapeId));
    _canvasBloc.add(canvas_event.ShapeSelected(event.shapeId));
  }

  void _onDeselected(ShapeDeselectedEvent event, Emitter<ShapeState> emit) {
    emit(state.copyWith(clearSelection: true, snapGuides: []));
    _canvasBloc.add(const canvas_event.ShapeDeselected());
  }

  void _onDragStarted(ShapeDragStarted event, Emitter<ShapeState> emit) {
    final shape = _findShape(event.shapeId);
    if (shape == null) return;
    // Snapshot shapes BEFORE the drag so the operation can be undone.
    _canvasBloc.add(const canvas_event.ShapeSnapshotRequested());
    _dragStart = event.startPoint;
    _dragStartBounds = shape.bounds;
    _dragShape = shape;
    emit(state.copyWith(
      selectedShapeId: event.shapeId,
      isDragging: true,
    ));
    _canvasBloc.add(canvas_event.ShapeSelected(event.shapeId));
  }

  void _onDragUpdated(ShapeDragUpdated event, Emitter<ShapeState> emit) {
    if (_dragStart == null || _dragStartBounds == null || _dragShape == null) {
      return;
    }
    final id = state.selectedShapeId;
    if (id == null) return;

    final delta = event.currentPoint - _dragStart!;
    final newOrigin =
        Offset(_dragStartBounds!.left + delta.dx, _dragStartBounds!.top + delta.dy);

    // Snap to other shapes
    final others = _canvasBloc.state.shapes
        .where((s) => s.id != id)
        .toList();
    final snapResult = SnapGuideEngine.snapToShapes(
      candidate: newOrigin,
      shapeSize: _dragStartBounds!.size,
      others: others,
    );

    final snappedBounds = snapResult.offset & _dragStartBounds!.size;
    final updated = _dragShape!.copyWith(bounds: snappedBounds);

    // Push live update to CanvasBloc so the canvas repaints immediately.
    _canvasBloc.add(canvas_event.ShapeUpdated(updated));
    emit(state.copyWith(snapGuides: snapResult.guides));
  }

  void _onDragEnded(ShapeDragEnded event, Emitter<ShapeState> emit) {
    _dragStart = null;
    _dragStartBounds = null;
    _dragShape = null;
    emit(state.copyWith(isDragging: false, snapGuides: []));
  }

  void _onHandleDragStarted(
      HandleDragStarted event, Emitter<ShapeState> emit) {
    final shape = _findShape(event.shapeId);
    if (shape == null) return;
    // Snapshot shapes BEFORE the resize so the operation can be undone.
    _canvasBloc.add(const canvas_event.ShapeSnapshotRequested());
    _dragStart = event.startPoint;
    _dragStartBounds = shape.bounds;
    _dragShape = shape;
    _activeHandleIndex = event.handleIndex;
    emit(state.copyWith(
      selectedShapeId: event.shapeId,
      isResizing: true,
    ));
    _canvasBloc.add(canvas_event.ShapeSelected(event.shapeId));
  }

  void _onHandleDragUpdated(
      HandleDragUpdated event, Emitter<ShapeState> emit) {
    if (_dragStart == null ||
        _dragStartBounds == null ||
        _activeHandleIndex == null ||
        _dragShape == null) return;
    final id = state.selectedShapeId;
    if (id == null) return;

    final delta = event.currentPoint - _dragStart!;
    final newBounds = _resizeBounds(
        _dragStartBounds!, _activeHandleIndex!, delta);

    if (newBounds.width < 8 || newBounds.height < 8) return;
    final updated = _dragShape!.copyWith(bounds: newBounds);
    _canvasBloc.add(canvas_event.ShapeUpdated(updated));
  }

  void _onHandleDragEnded(HandleDragEnded event, Emitter<ShapeState> emit) {
    _dragStart = null;
    _dragStartBounds = null;
    _activeHandleIndex = null;
    _dragShape = null;
    emit(state.copyWith(isResizing: false, snapGuides: []));
  }

  void _onStyleUpdated(ShapeStyleUpdated event, Emitter<ShapeState> emit) {
    final id = state.selectedShapeId;
    if (id == null) return;
    final shape = _findShape(id);
    if (shape == null) return;
    // Snapshot BEFORE the style change so it can be undone.
    _canvasBloc.add(const canvas_event.ShapeSnapshotRequested());
    final updated = shape.copyWith(
      strokeColor: event.strokeColor,
      fillColor: event.fillColor,
      strokeWidth: event.strokeWidth,
      cornerRadius: event.cornerRadius,
      opacity: event.opacity,
      isFilled: event.isFilled,
      fillPattern: event.fillPattern,
    );
    _canvasBloc.add(canvas_event.ShapeUpdated(updated));
  }

  void _onTypeChanged(ShapeTypeChanged event, Emitter<ShapeState> emit) {
    final id = state.selectedShapeId;
    if (id == null) return;
    final shape = _findShape(id);
    if (shape == null) return;
    // Snapshot BEFORE the type change so it can be undone.
    _canvasBloc.add(const canvas_event.ShapeSnapshotRequested());
    final updated = shape.copyWith(type: event.type);
    _canvasBloc.add(canvas_event.ShapeUpdated(updated));
  }

  void _onDeleteRequested(
      ShapeDeleteRequested event, Emitter<ShapeState> emit) {
    final id = state.selectedShapeId;
    if (id == null) return;
    // Snapshot BEFORE delete so it can be undone.
    _canvasBloc.add(const canvas_event.ShapeSnapshotRequested());
    _canvasBloc.add(canvas_event.ShapeDeleted(id));
    emit(state.copyWith(clearSelection: true, snapGuides: []));
  }

  void _onDuplicateRequested(
      ShapeDuplicateRequested event, Emitter<ShapeState> emit) {
    final id = state.selectedShapeId;
    if (id == null) return;
    final shape = _findShape(id);
    if (shape == null) return;
    const offsetDelta = Offset(20, 20);
    final duplicate = shape.copyWith(
      id: _uuid.v4(),
      bounds: shape.bounds.translate(offsetDelta.dx, offsetDelta.dy),
    );
    // Snapshot BEFORE add so it can be undone.
    _canvasBloc.add(const canvas_event.ShapeSnapshotRequested());
    _canvasBloc.add(canvas_event.ShapeAdded(duplicate));
    emit(state.copyWith(selectedShapeId: duplicate.id));
    _canvasBloc.add(canvas_event.ShapeSelected(duplicate.id));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Look up a shape by ID from CanvasBloc (single source of truth).
  ShapeElement? _findShape(String id) =>
      _canvasBloc.state.shapes.where((s) => s.id == id).firstOrNull;

  /// Compute new bounds after dragging handle [index] by [delta].
  Rect _resizeBounds(Rect original, int index, Offset delta) {
    var l = original.left;
    var t = original.top;
    var r = original.right;
    var b = original.bottom;

    switch (index) {
      case 0: // TL
        l += delta.dx;
        t += delta.dy;
      case 1: // TC
        t += delta.dy;
      case 2: // TR
        r += delta.dx;
        t += delta.dy;
      case 3: // MR
        r += delta.dx;
      case 4: // BR
        r += delta.dx;
        b += delta.dy;
      case 5: // BC
        b += delta.dy;
      case 6: // BL
        l += delta.dx;
        b += delta.dy;
      case 7: // ML
        l += delta.dx;
    }
    if (l > r) {
      final tmp = l;
      l = r;
      r = tmp;
    }
    if (t > b) {
      final tmp = t;
      t = b;
      b = tmp;
    }
    return Rect.fromLTRB(l, t, r, b);
  }
}
