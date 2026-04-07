import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/canvas_node.dart';
import '../../engine/auto_layout.dart';
import '../../engine/infinite_canvas_engine.dart';
import 'infinite_canvas_event.dart';
import 'infinite_canvas_state.dart';

/// Maximum undo history steps.
const _maxHistory = 100;

/// BLoC managing the entire infinite canvas state.
class InfiniteCanvasBloc
    extends Bloc<InfiniteCanvasEvent, InfiniteCanvasState> {
  InfiniteCanvasBloc() : super(const InfiniteCanvasState()) {
    on<AddNode>(_onAddNode);
    on<RemoveNode>(_onRemoveNode);
    on<UpdateNode>(_onUpdateNode);
    on<MoveNode>(_onMoveNode);
    on<ResizeNode>(_onResizeNode);
    on<RotateNode>(_onRotateNode);

    on<AddEdge>(_onAddEdge);
    on<RemoveEdge>(_onRemoveEdge);
    on<UpdateEdge>(_onUpdateEdge);

    on<SelectNode>(_onSelectNode);
    on<SelectMultiple>(_onSelectMultiple);
    on<DeselectAll>(_onDeselectAll);
    on<SelectAll>(_onSelectAll);
    on<SelectEdge>(_onSelectEdge);

    on<PanViewport>(_onPan);
    on<ZoomViewport>(_onZoom);
    on<SetZoom>(_onSetZoom);
    on<ZoomToFit>(_onZoomToFit);
    on<ZoomToSelection>(_onZoomToSelection);
    on<ResetZoom>(_onResetZoom);
    on<UpdateScreenSize>(_onUpdateScreenSize);

    on<ApplyLayout>(_onApplyLayout);

    on<GroupSelected>(_onGroupSelected);
    on<UngroupNode>(_onUngroupNode);

    on<UndoAction>(_onUndo);
    on<RedoAction>(_onRedo);

    on<CopySelected>(_onCopy);
    on<CutSelected>(_onCut);
    on<PasteNodes>(_onPaste);
    on<DuplicateSelected>(_onDuplicate);

    on<SetActiveTool>(_onSetActiveTool);
    on<ToggleMinimap>(_onToggleMinimap);
  }

  // ── History helpers ────────────────────────────────────────────────────────

  InfiniteCanvasState _pushHistory(InfiniteCanvasState s) {
    final snap = (nodes: Map.of(s.nodes), edges: Map.of(s.edges));
    final stack = [...s.undoStack, snap];
    return s.copyWith(
      undoStack: stack.length > _maxHistory
          ? stack.sublist(stack.length - _maxHistory)
          : stack,
      redoStack: const [],
    );
  }

  // ── Node handlers ──────────────────────────────────────────────────────────

  void _onAddNode(AddNode event, Emitter<InfiniteCanvasState> emit) {
    final s = _pushHistory(state);
    emit(s.copyWith(nodes: {...s.nodes, event.node.id: event.node}));
  }

  void _onRemoveNode(RemoveNode event, Emitter<InfiniteCanvasState> emit) {
    final s = _pushHistory(state);
    final nodes = Map.of(s.nodes)..remove(event.nodeId);
    // Also remove edges connected to this node.
    final edges = Map.of(s.edges)
      ..removeWhere(
        (_, e) =>
            e.sourceNodeId == event.nodeId || e.targetNodeId == event.nodeId,
      );
    final sel = Set.of(s.selectedNodeIds)..remove(event.nodeId);
    emit(s.copyWith(nodes: nodes, edges: edges, selectedNodeIds: sel));
  }

  void _onUpdateNode(UpdateNode event, Emitter<InfiniteCanvasState> emit) {
    final s = _pushHistory(state);
    emit(s.copyWith(nodes: {...s.nodes, event.node.id: event.node}));
  }

  void _onMoveNode(MoveNode event, Emitter<InfiniteCanvasState> emit) {
    final node = state.nodes[event.nodeId];
    if (node == null) return;
    final updated = node.copyWithBase(worldPosition: event.newPosition);
    final s = _pushHistory(state);
    emit(s.copyWith(nodes: {...s.nodes, node.id: updated}));
  }

  void _onResizeNode(ResizeNode event, Emitter<InfiniteCanvasState> emit) {
    final node = state.nodes[event.nodeId];
    if (node == null) return;
    final updated = node.copyWithBase(worldSize: event.newSize);
    final s = _pushHistory(state);
    emit(s.copyWith(nodes: {...s.nodes, node.id: updated}));
  }

  void _onRotateNode(RotateNode event, Emitter<InfiniteCanvasState> emit) {
    final node = state.nodes[event.nodeId];
    if (node == null) return;
    final updated = node.copyWithBase(rotation: event.radians);
    final s = _pushHistory(state);
    emit(s.copyWith(nodes: {...s.nodes, node.id: updated}));
  }

  // ── Edge handlers ──────────────────────────────────────────────────────────

  void _onAddEdge(AddEdge event, Emitter<InfiniteCanvasState> emit) {
    final s = _pushHistory(state);
    emit(s.copyWith(edges: {...s.edges, event.edge.id: event.edge}));
  }

  void _onRemoveEdge(RemoveEdge event, Emitter<InfiniteCanvasState> emit) {
    final s = _pushHistory(state);
    final edges = Map.of(s.edges)..remove(event.edgeId);
    emit(s.copyWith(
      edges: edges,
      selectedEdgeId: s.selectedEdgeId == event.edgeId ? null : s.selectedEdgeId,
    ));
  }

  void _onUpdateEdge(UpdateEdge event, Emitter<InfiniteCanvasState> emit) {
    final s = _pushHistory(state);
    emit(s.copyWith(edges: {...s.edges, event.edge.id: event.edge}));
  }

  // ── Selection handlers ─────────────────────────────────────────────────────

  void _onSelectNode(SelectNode event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(selectedNodeIds: {event.nodeId}, selectedEdgeId: null));

  void _onSelectMultiple(SelectMultiple event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(
        selectedNodeIds: {...state.selectedNodeIds, ...event.nodeIds},
        selectedEdgeId: null,
      ));

  void _onDeselectAll(DeselectAll event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(selectedNodeIds: const {}, selectedEdgeId: null));

  void _onSelectAll(SelectAll event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(selectedNodeIds: state.nodes.keys.toSet()));

  void _onSelectEdge(SelectEdge event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(
        selectedEdgeId: event.edgeId,
        selectedNodeIds: const {},
      ));

  // ── Viewport handlers ──────────────────────────────────────────────────────

  void _onPan(PanViewport event, Emitter<InfiniteCanvasState> emit) {
    final newOffset = state.viewportOffset - event.delta / state.zoomLevel;
    emit(state.copyWith(viewportOffset: newOffset));
  }

  void _onZoom(ZoomViewport event, Emitter<InfiniteCanvasState> emit) {
    final engine = InfiniteCanvasEngine(
      worldOffset: state.viewportOffset,
      zoomLevel: state.zoomLevel,
      screenSize: state.screenSize,
    );
    engine.zoomBy(event.factor, focalScreenPoint: event.focalPoint);
    emit(state.copyWith(
      viewportOffset: engine.worldOffset,
      zoomLevel: engine.zoomLevel,
    ));
  }

  void _onSetZoom(SetZoom event, Emitter<InfiniteCanvasState> emit) {
    final level = event.level
        .clamp(InfiniteCanvasEngine.minZoom, InfiniteCanvasEngine.maxZoom);
    emit(state.copyWith(zoomLevel: level));
  }

  void _onZoomToFit(ZoomToFit event, Emitter<InfiniteCanvasState> emit) {
    if (state.nodes.isEmpty) return;
    final engine = InfiniteCanvasEngine(
      worldOffset: state.viewportOffset,
      zoomLevel: state.zoomLevel,
      screenSize: state.screenSize,
    );
    engine.fitToContent(
      state.nodes.values.map((n) => n.worldBounds).toList(),
    );
    emit(state.copyWith(
      viewportOffset: engine.worldOffset,
      zoomLevel: engine.zoomLevel,
    ));
  }

  void _onZoomToSelection(
      ZoomToSelection event, Emitter<InfiniteCanvasState> emit) {
    final selected = state.selectedNodeIds
        .map((id) => state.nodes[id])
        .whereType<CanvasNode>()
        .toList();
    if (selected.isEmpty) return;
    final engine = InfiniteCanvasEngine(
      worldOffset: state.viewportOffset,
      zoomLevel: state.zoomLevel,
      screenSize: state.screenSize,
    );
    engine.fitToContent(selected.map((n) => n.worldBounds).toList());
    emit(state.copyWith(
      viewportOffset: engine.worldOffset,
      zoomLevel: engine.zoomLevel,
    ));
  }

  void _onResetZoom(ResetZoom event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(viewportOffset: Offset.zero, zoomLevel: 1.0));

  void _onUpdateScreenSize(
      UpdateScreenSize event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(screenSize: event.size));

  // ── Layout handler ─────────────────────────────────────────────────────────

  void _onApplyLayout(ApplyLayout event, Emitter<InfiniteCanvasState> emit) {
    final newPositions = AutoLayout.layout(
      nodes: state.nodes.values.toList(),
      edges: state.edges.values.toList(),
      algorithm: event.algorithm,
      center: event.center,
      spacing: event.spacing,
    );
    final s = _pushHistory(state);
    final updatedNodes = Map.of(s.nodes);
    for (final entry in newPositions.entries) {
      final node = updatedNodes[entry.key];
      if (node != null) {
        updatedNodes[entry.key] =
            node.copyWithBase(worldPosition: entry.value);
      }
    }
    emit(s.copyWith(nodes: updatedNodes, activeLayout: event.algorithm));
  }

  // ── Group / Ungroup ────────────────────────────────────────────────────────

  void _onGroupSelected(
      GroupSelected event, Emitter<InfiniteCanvasState> emit) {
    if (state.selectedNodeIds.length < 2) return;
    final selected = state.selectedNodeIds
        .map((id) => state.nodes[id])
        .whereType<CanvasNode>()
        .toList();

    // Compute bounding rect of selected nodes.
    final bounds = selected.fold<Rect>(
      selected.first.worldBounds,
      (acc, n) => acc.expandToInclude(n.worldBounds),
    );

    final group = GroupNode.create(
      worldPosition: bounds.center,
      worldSize: bounds.size,
      childNodeIds: state.selectedNodeIds.toList(),
      groupLabel: event.label,
    );

    final s = _pushHistory(state);
    emit(s.copyWith(
      nodes: {...s.nodes, group.id: group},
      selectedNodeIds: {group.id},
    ));
  }

  void _onUngroupNode(UngroupNode event, Emitter<InfiniteCanvasState> emit) {
    final group = state.nodes[event.groupNodeId];
    if (group is! GroupNode) return;
    final s = _pushHistory(state);
    final nodes = Map.of(s.nodes)..remove(group.id);
    emit(s.copyWith(
      nodes: nodes,
      selectedNodeIds: group.childNodeIds.toSet(),
    ));
  }

  // ── History ────────────────────────────────────────────────────────────────

  void _onUndo(UndoAction event, Emitter<InfiniteCanvasState> emit) {
    if (!state.canUndo) return;
    final snap = state.undoStack.last;
    final undoStack = state.undoStack.sublist(0, state.undoStack.length - 1);
    final currentSnap = (nodes: Map.of(state.nodes), edges: Map.of(state.edges));
    emit(state.copyWith(
      nodes: snap.nodes,
      edges: snap.edges,
      undoStack: undoStack,
      redoStack: [...state.redoStack, currentSnap],
      selectedNodeIds: const {},
    ));
  }

  void _onRedo(RedoAction event, Emitter<InfiniteCanvasState> emit) {
    if (!state.canRedo) return;
    final snap = state.redoStack.last;
    final redoStack = state.redoStack.sublist(0, state.redoStack.length - 1);
    final currentSnap = (nodes: Map.of(state.nodes), edges: Map.of(state.edges));
    emit(state.copyWith(
      nodes: snap.nodes,
      edges: snap.edges,
      redoStack: redoStack,
      undoStack: [...state.undoStack, currentSnap],
      selectedNodeIds: const {},
    ));
  }

  // ── Clipboard ──────────────────────────────────────────────────────────────

  void _onCopy(CopySelected event, Emitter<InfiniteCanvasState> emit) {
    final clipboard = state.selectedNodeIds
        .map((id) => state.nodes[id])
        .whereType<CanvasNode>()
        .toList();
    emit(state.copyWith(clipboard: clipboard));
  }

  void _onCut(CutSelected event, Emitter<InfiniteCanvasState> emit) {
    final clipboard = state.selectedNodeIds
        .map((id) => state.nodes[id])
        .whereType<CanvasNode>()
        .toList();
    final s = _pushHistory(state);
    final nodes = Map.of(s.nodes)
      ..removeWhere((id, _) => s.selectedNodeIds.contains(id));
    emit(s.copyWith(
      nodes: nodes,
      clipboard: clipboard,
      selectedNodeIds: const {},
    ));
  }

  void _onPaste(PasteNodes event, Emitter<InfiniteCanvasState> emit) {
    if (state.clipboard.isEmpty) return;
    final s = _pushHistory(state);
    final newNodes = <String, CanvasNode>{};
    for (final node in s.clipboard) {
      final pasted = node.copyWithBase(
        worldPosition: node.worldPosition + event.offset + const Offset(20, 20),
      );
      // Re-generate ID by creating a new id via copyWithBase hack:
      // We rely on each subtype's factory; here we just reuse the existing node
      // shifted slightly.
      newNodes[pasted.id] = pasted;
    }
    emit(s.copyWith(
      nodes: {...s.nodes, ...newNodes},
      selectedNodeIds: newNodes.keys.toSet(),
    ));
  }

  void _onDuplicate(DuplicateSelected event, Emitter<InfiniteCanvasState> emit) {
    if (state.selectedNodeIds.isEmpty) return;
    final s = _pushHistory(state);
    final newNodes = <String, CanvasNode>{};
    for (final id in s.selectedNodeIds) {
      final node = s.nodes[id];
      if (node == null) continue;
      final dup = node.copyWithBase(
        worldPosition: node.worldPosition + const Offset(30, 30),
      );
      newNodes[dup.id] = dup;
    }
    emit(s.copyWith(
      nodes: {...s.nodes, ...newNodes},
      selectedNodeIds: newNodes.keys.toSet(),
    ));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  void _onSetActiveTool(SetActiveTool event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(activeTool: event.tool));

  void _onToggleMinimap(ToggleMinimap event, Emitter<InfiniteCanvasState> emit) =>
      emit(state.copyWith(isMinimapVisible: !state.isMinimapVisible));
}
