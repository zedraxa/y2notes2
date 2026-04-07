import 'package:flutter/material.dart';
import '../../domain/entities/canvas_edge.dart';
import '../../domain/entities/canvas_node.dart';
import '../../engine/auto_layout.dart';
import 'infinite_canvas_event.dart';

/// Immutable state for the infinite canvas.
class InfiniteCanvasState {
  const InfiniteCanvasState({
    this.nodes = const {},
    this.edges = const {},
    this.selectedNodeIds = const {},
    this.selectedEdgeId,
    this.viewportOffset = Offset.zero,
    this.zoomLevel = 1.0,
    this.screenSize = Size.zero,
    this.activeTool = InfiniteCanvasTool.select,
    this.isMinimapVisible = true,
    this.activeLayout,
    this.undoStack = const [],
    this.redoStack = const [],
    this.clipboard = const [],
  });

  // ── Canvas data ──────────────────────────────────────────────────────────

  /// All nodes keyed by ID.
  final Map<String, CanvasNode> nodes;

  /// All edges keyed by ID.
  final Map<String, CanvasEdge> edges;

  // ── Selection ────────────────────────────────────────────────────────────

  final Set<String> selectedNodeIds;
  final String? selectedEdgeId;

  // ── Viewport ──────────────────────────────────────────────────────────────

  /// World-space point at the centre of the viewport.
  final Offset viewportOffset;

  /// Current zoom level (1.0 = 100 %).
  final double zoomLevel;

  /// Screen size in pixels.
  final Size screenSize;

  // ── UI ────────────────────────────────────────────────────────────────────

  final InfiniteCanvasTool activeTool;
  final bool isMinimapVisible;
  final LayoutAlgorithm? activeLayout;

  // ── History ───────────────────────────────────────────────────────────────

  /// Each entry is a snapshot of (nodes, edges).
  final List<({Map<String, CanvasNode> nodes, Map<String, CanvasEdge> edges})>
      undoStack;

  final List<({Map<String, CanvasNode> nodes, Map<String, CanvasEdge> edges})>
      redoStack;

  // ── Clipboard ─────────────────────────────────────────────────────────────

  final List<CanvasNode> clipboard;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  InfiniteCanvasState copyWith({
    Map<String, CanvasNode>? nodes,
    Map<String, CanvasEdge>? edges,
    Set<String>? selectedNodeIds,
    Object? selectedEdgeId = _sentinel,
    Offset? viewportOffset,
    double? zoomLevel,
    Size? screenSize,
    InfiniteCanvasTool? activeTool,
    bool? isMinimapVisible,
    LayoutAlgorithm? activeLayout,
    List<({Map<String, CanvasNode> nodes, Map<String, CanvasEdge> edges})>?
        undoStack,
    List<({Map<String, CanvasNode> nodes, Map<String, CanvasEdge> edges})>?
        redoStack,
    List<CanvasNode>? clipboard,
  }) =>
      InfiniteCanvasState(
        nodes: nodes ?? this.nodes,
        edges: edges ?? this.edges,
        selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
        selectedEdgeId: identical(selectedEdgeId, _sentinel)
            ? this.selectedEdgeId
            : selectedEdgeId as String?,
        viewportOffset: viewportOffset ?? this.viewportOffset,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        screenSize: screenSize ?? this.screenSize,
        activeTool: activeTool ?? this.activeTool,
        isMinimapVisible: isMinimapVisible ?? this.isMinimapVisible,
        activeLayout: activeLayout ?? this.activeLayout,
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
        clipboard: clipboard ?? this.clipboard,
      );

  static const Object _sentinel = Object();
}
