import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/canvas_edge.dart';
import '../../domain/entities/canvas_node.dart';
import '../../engine/infinite_canvas_engine.dart';
import '../bloc/infinite_canvas_bloc.dart';
import '../bloc/infinite_canvas_event.dart';
import '../bloc/infinite_canvas_state.dart';

/// Wraps the canvas surface with all gesture and keyboard handling.
///
/// Responsibilities:
/// - Pan (drag on empty area / hand tool)
/// - Pinch-to-zoom
/// - Tap to select / deselect
/// - Drag to move selected nodes
/// - Rubber-band multi-select
/// - Connection drag (connection tool)
/// - Node context menu (long press)
/// - Keyboard shortcuts (desktop)
class NodeInteractionHandler extends StatefulWidget {
  const NodeInteractionHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<NodeInteractionHandler> createState() => _NodeInteractionHandlerState();
}

class _NodeInteractionHandlerState extends State<NodeInteractionHandler> {
  // ── Drag state ─────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Map<String, Offset>? _nodeDragStartPositions;
  bool _isDraggingNodes = false;
  bool _isPanning = false;

  // Rubber-band selection.
  Offset? _rubberBandStart;
  Offset? _rubberBandEnd;

  // Connection drag.
  String? _connectionSourceId;
  Offset? _connectionEnd;

  // ── Helpers ───────────────────────────────────────────────────────────────

  InfiniteCanvasBloc get _bloc => context.read<InfiniteCanvasBloc>();
  InfiniteCanvasState get _state => _bloc.state;

  Offset _screenToWorld(Offset screen) {
    final engine = InfiniteCanvasEngine(
      worldOffset: _state.viewportOffset,
      zoomLevel: _state.zoomLevel,
      screenSize: _state.screenSize,
    );
    return engine.screenToWorld(screen);
  }

  CanvasNode? _nodeAt(Offset worldPos) {
    // Iterate nodes in reverse z-order.
    final sorted = _state.nodes.values.toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (final node in sorted) {
      if (node.worldBounds.contains(worldPos)) return node;
    }
    return null;
  }

  // ── Gesture handlers ───────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails details) {
    _dragStart = details.focalPoint;

    if (_state.activeTool == InfiniteCanvasTool.hand) {
      _isPanning = true;
      return;
    }

    final worldPos = _screenToWorld(details.focalPoint);
    final hit = _nodeAt(worldPos);

    if (_state.activeTool == InfiniteCanvasTool.connection) {
      if (hit != null) {
        _connectionSourceId = hit.id;
        _connectionEnd = details.focalPoint;
      }
      return;
    }

    if (hit != null) {
      if (!_state.selectedNodeIds.contains(hit.id)) {
        _bloc.add(SelectNode(hit.id));
      }
      _isDraggingNodes = true;
      _nodeDragStartPositions = {
        for (final id in _state.selectedNodeIds)
          if (_state.nodes[id] != null)
            id: _state.nodes[id]!.worldPosition,
      };
    } else {
      // Start rubber-band selection.
      _bloc.add(const DeselectAll());
      _rubberBandStart = details.focalPoint;
      _rubberBandEnd = details.focalPoint;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Pinch-to-zoom.
    if (details.scale != 1.0) {
      _bloc.add(ZoomViewport(
        factor: details.scale,
        focalPoint: details.focalPoint,
      ));
      return;
    }

    final delta = details.focalPoint - (_dragStart ?? details.focalPoint);
    _dragStart = details.focalPoint;

    if (_isPanning || _state.activeTool == InfiniteCanvasTool.hand) {
      _bloc.add(PanViewport(-delta));
      return;
    }

    if (_connectionSourceId != null) {
      setState(() => _connectionEnd = details.focalPoint);
      return;
    }

    if (_isDraggingNodes && _nodeDragStartPositions != null) {
      // Move all selected nodes.
      final worldDelta = delta / _state.zoomLevel;
      for (final id in _state.selectedNodeIds) {
        final node = _state.nodes[id];
        if (node == null || node.isLocked) continue;
        _bloc.add(MoveNode(
          nodeId: id,
          newPosition: node.worldPosition + worldDelta,
        ));
      }
      return;
    }

    if (_rubberBandStart != null) {
      setState(() => _rubberBandEnd = details.focalPoint);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_connectionSourceId != null && _connectionEnd != null) {
      final worldEnd = _screenToWorld(_connectionEnd!);
      final targetNode = _nodeAt(worldEnd);
      if (targetNode != null && targetNode.id != _connectionSourceId) {
        _bloc.add(AddEdge(CanvasEdge.create(
          sourceNodeId: _connectionSourceId!,
          targetNodeId: targetNode.id,
        )));
      }
      _connectionSourceId = null;
      _connectionEnd = null;
      setState(() {});
      return;
    }

    if (_rubberBandStart != null && _rubberBandEnd != null) {
      final worldStart = _screenToWorld(_rubberBandStart!);
      final worldEnd = _screenToWorld(_rubberBandEnd!);
      final selRect = Rect.fromPoints(worldStart, worldEnd);
      final inside = _state.nodes.values
          .where((n) => selRect.overlaps(n.worldBounds))
          .map((n) => n.id)
          .toSet();
      if (inside.isNotEmpty) {
        _bloc.add(SelectMultiple(inside));
      }
    }

    _dragStart = null;
    _isDraggingNodes = false;
    _nodeDragStartPositions = null;
    _isPanning = false;
    _rubberBandStart = null;
    _rubberBandEnd = null;
    setState(() {});
  }

  void _onTap(TapDownDetails details) {
    final worldPos = _screenToWorld(details.localPosition);
    final hit = _nodeAt(worldPos);
    if (hit != null) {
      _bloc.add(SelectNode(hit.id));
    } else {
      _bloc.add(const DeselectAll());
    }
  }

  void _onLongPress(LongPressStartDetails details) {
    final worldPos = _screenToWorld(details.localPosition);
    final hit = _nodeAt(worldPos);
    if (hit == null) return;
    _showContextMenu(context, details.globalPosition, hit);
  }

  void _showContextMenu(
      BuildContext ctx, Offset position, CanvasNode node) async {
    final bloc = _bloc;
    final result = await showMenu<_ContextAction>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
            value: _ContextAction.duplicate, child: Text('Duplicate')),
        const PopupMenuItem(
            value: _ContextAction.delete, child: Text('Delete')),
        const PopupMenuItem(
            value: _ContextAction.lock, child: Text('Toggle Lock')),
      ],
    );
    if (result == null) return;
    switch (result) {
      case _ContextAction.delete:
        bloc.add(RemoveNode(node.id));
      case _ContextAction.duplicate:
        bloc.add(SelectNode(node.id));
        bloc.add(const DuplicateSelected());
      case _ContextAction.lock:
        bloc.add(UpdateNode(node.copyWithBase(isLocked: !node.isLocked)));
    }
  }

  // ── Keyboard shortcuts ─────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      for (final id in _state.selectedNodeIds.toList()) {
        _bloc.add(RemoveNode(id));
      }
      return KeyEventResult.handled;
    }

    if (isCtrl) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyA:
          _bloc.add(const SelectAll());
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyC:
          _bloc.add(const CopySelected());
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyX:
          _bloc.add(const CutSelected());
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyV:
          _bloc.add(const PasteNodes());
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyZ:
          if (HardwareKeyboard.instance.isShiftPressed) {
            _bloc.add(const RedoAction());
          } else {
            _bloc.add(const UndoAction());
          }
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyY:
          _bloc.add(const RedoAction());
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyG:
          _bloc.add(const GroupSelected());
          return KeyEventResult.handled;
        default:
          break;
      }
    }

    return KeyEventResult.ignored;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          GestureDetector(
            onTapDown: _onTap,
            onLongPressStart: _onLongPress,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: widget.child,
          ),
          // Rubber-band selection overlay.
          if (_rubberBandStart != null && _rubberBandEnd != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RubberBandPainter(
                    start: _rubberBandStart!,
                    end: _rubberBandEnd!,
                  ),
                ),
              ),
            ),
          // Connection drag overlay.
          if (_connectionEnd != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConnectionDragPainter(
                    end: _connectionEnd!,
                    state: _state,
                    sourceId: _connectionSourceId,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ContextAction { delete, duplicate, lock }

// ── Rubber-band painter ────────────────────────────────────────────────────

class _RubberBandPainter extends CustomPainter {
  const _RubberBandPainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_RubberBandPainter old) =>
      old.start != start || old.end != end;
}

// ── Connection drag painter ───────────────────────────────────────────────

class _ConnectionDragPainter extends CustomPainter {
  const _ConnectionDragPainter({
    required this.end,
    required this.state,
    this.sourceId,
  });

  final Offset end;
  final InfiniteCanvasState state;
  final String? sourceId;

  @override
  void paint(Canvas canvas, Size size) {
    if (sourceId == null) return;
    final node = state.nodes[sourceId];
    if (node == null) return;

    final engine = InfiniteCanvasEngine(
      worldOffset: state.viewportOffset,
      zoomLevel: state.zoomLevel,
      screenSize: state.screenSize,
    );
    final src = engine.worldToScreen(node.worldPosition);
    final path = Path()
      ..moveTo(src.dx, src.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ConnectionDragPainter old) => old.end != end;
}
