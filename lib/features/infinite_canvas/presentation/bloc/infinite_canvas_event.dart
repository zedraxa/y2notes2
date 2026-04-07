import 'package:flutter/material.dart';
import '../../domain/entities/canvas_edge.dart';
import '../../domain/entities/canvas_node.dart';
import '../../engine/auto_layout.dart';

/// The active tool on the infinite canvas.
enum InfiniteCanvasTool {
  select,
  hand,
  drawRegion,
  textCard,
  stickyNote,
  connection,
  frame,
  shape,
  image,
}

// ─────────────────────────────────────────────────────────────────────────────
// Node events
// ─────────────────────────────────────────────────────────────────────────────

abstract class InfiniteCanvasEvent {
  const InfiniteCanvasEvent();
}

/// Add a new node to the canvas.
class AddNode extends InfiniteCanvasEvent {
  const AddNode(this.node);
  final CanvasNode node;
}

/// Remove a node and its connected edges.
class RemoveNode extends InfiniteCanvasEvent {
  const RemoveNode(this.nodeId);
  final String nodeId;
}

/// Replace a node with an updated version (same id).
class UpdateNode extends InfiniteCanvasEvent {
  const UpdateNode(this.node);
  final CanvasNode node;
}

/// Move a node to [newPosition] (world-space centre).
class MoveNode extends InfiniteCanvasEvent {
  const MoveNode({required this.nodeId, required this.newPosition});
  final String nodeId;
  final Offset newPosition;
}

/// Resize a node to [newSize].
class ResizeNode extends InfiniteCanvasEvent {
  const ResizeNode({required this.nodeId, required this.newSize});
  final String nodeId;
  final Size newSize;
}

/// Rotate a node to [radians].
class RotateNode extends InfiniteCanvasEvent {
  const RotateNode({required this.nodeId, required this.radians});
  final String nodeId;
  final double radians;
}

// ─────────────────────────────────────────────────────────────────────────────
// Edge events
// ─────────────────────────────────────────────────────────────────────────────

/// Add a new edge.
class AddEdge extends InfiniteCanvasEvent {
  const AddEdge(this.edge);
  final CanvasEdge edge;
}

/// Remove an edge by id.
class RemoveEdge extends InfiniteCanvasEvent {
  const RemoveEdge(this.edgeId);
  final String edgeId;
}

/// Replace an edge with an updated version.
class UpdateEdge extends InfiniteCanvasEvent {
  const UpdateEdge(this.edge);
  final CanvasEdge edge;
}

// ─────────────────────────────────────────────────────────────────────────────
// Selection events
// ─────────────────────────────────────────────────────────────────────────────

/// Select a single node.
class SelectNode extends InfiniteCanvasEvent {
  const SelectNode(this.nodeId);
  final String nodeId;
}

/// Add multiple nodes to the selection (rubber-band / shift-click).
class SelectMultiple extends InfiniteCanvasEvent {
  const SelectMultiple(this.nodeIds);
  final Set<String> nodeIds;
}

/// Deselect all nodes and edges.
class DeselectAll extends InfiniteCanvasEvent {
  const DeselectAll();
}

/// Select every node on the canvas.
class SelectAll extends InfiniteCanvasEvent {
  const SelectAll();
}

/// Select a single edge.
class SelectEdge extends InfiniteCanvasEvent {
  const SelectEdge(this.edgeId);
  final String edgeId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewport events
// ─────────────────────────────────────────────────────────────────────────────

/// Pan the viewport by [delta] in screen pixels.
class PanViewport extends InfiniteCanvasEvent {
  const PanViewport(this.delta);
  final Offset delta;
}

/// Zoom by [factor] around [focalPoint] (screen coordinates).
class ZoomViewport extends InfiniteCanvasEvent {
  const ZoomViewport({required this.factor, this.focalPoint});
  final double factor;
  final Offset? focalPoint;
}

/// Set an absolute zoom level.
class SetZoom extends InfiniteCanvasEvent {
  const SetZoom(this.level);
  final double level;
}

/// Fit viewport to show all nodes.
class ZoomToFit extends InfiniteCanvasEvent {
  const ZoomToFit();
}

/// Fit viewport to show selected nodes.
class ZoomToSelection extends InfiniteCanvasEvent {
  const ZoomToSelection();
}

/// Reset zoom to 1.0 and centre on origin.
class ResetZoom extends InfiniteCanvasEvent {
  const ResetZoom();
}

/// Update the screen size (called when widget resizes).
class UpdateScreenSize extends InfiniteCanvasEvent {
  const UpdateScreenSize(this.size);
  final Size size;
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout events
// ─────────────────────────────────────────────────────────────────────────────

/// Apply an auto-layout algorithm.
class ApplyLayout extends InfiniteCanvasEvent {
  const ApplyLayout({
    required this.algorithm,
    this.center = Offset.zero,
    this.spacing = 200.0,
  });
  final LayoutAlgorithm algorithm;
  final Offset center;
  final double spacing;
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouping events
// ─────────────────────────────────────────────────────────────────────────────

/// Group the currently selected nodes.
class GroupSelected extends InfiniteCanvasEvent {
  const GroupSelected({this.label});
  final String? label;
}

/// Ungroup a group node.
class UngroupNode extends InfiniteCanvasEvent {
  const UngroupNode(this.groupNodeId);
  final String groupNodeId;
}

// ─────────────────────────────────────────────────────────────────────────────
// History events
// ─────────────────────────────────────────────────────────────────────────────

/// Undo the last action.
class UndoAction extends InfiniteCanvasEvent {
  const UndoAction();
}

/// Redo the last undone action.
class RedoAction extends InfiniteCanvasEvent {
  const RedoAction();
}

// ─────────────────────────────────────────────────────────────────────────────
// Clipboard events
// ─────────────────────────────────────────────────────────────────────────────

/// Copy selected nodes to the internal clipboard.
class CopySelected extends InfiniteCanvasEvent {
  const CopySelected();
}

/// Cut selected nodes to the internal clipboard.
class CutSelected extends InfiniteCanvasEvent {
  const CutSelected();
}

/// Paste nodes from the clipboard at an optional [offset].
class PasteNodes extends InfiniteCanvasEvent {
  const PasteNodes({this.offset = Offset.zero});
  final Offset offset;
}

/// Duplicate selected nodes in-place (slight offset).
class DuplicateSelected extends InfiniteCanvasEvent {
  const DuplicateSelected();
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool & UI events
// ─────────────────────────────────────────────────────────────────────────────

/// Change the active editing tool.
class SetActiveTool extends InfiniteCanvasEvent {
  const SetActiveTool(this.tool);
  final InfiniteCanvasTool tool;
}

/// Toggle minimap visibility.
class ToggleMinimap extends InfiniteCanvasEvent {
  const ToggleMinimap();
}
