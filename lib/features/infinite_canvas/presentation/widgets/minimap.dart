import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/canvas_node.dart';
import '../bloc/infinite_canvas_bloc.dart';
import '../bloc/infinite_canvas_event.dart';
import '../bloc/infinite_canvas_state.dart';

/// A small overview panel that renders all nodes as dots/rectangles,
/// shows the current viewport as a translucent rectangle, and allows
/// tapping or dragging to navigate the canvas.
class Minimap extends StatelessWidget {
  const Minimap({
    super.key,
    this.width = 150,
    this.height = 100,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfiniteCanvasBloc, InfiniteCanvasState>(
      builder: (context, state) {
        return GestureDetector(
          onTapDown: (details) =>
              _handleTap(context, state, details.localPosition),
          onPanUpdate: (details) =>
              _handleDrag(context, state, details.localPosition),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: CustomPaint(
              painter: _MinimapPainter(
                nodes: state.nodes,
                viewportOffset: state.viewportOffset,
                zoomLevel: state.zoomLevel,
                screenSize: state.screenSize,
                mapSize: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    InfiniteCanvasState state,
    Offset localPos,
  ) {
    final worldPos = _localToWorld(localPos, state);
    context.read<InfiniteCanvasBloc>().add(
          PanViewport(
            (worldPos - state.viewportOffset) * state.zoomLevel,
          ),
        );
  }

  void _handleDrag(
    BuildContext context,
    InfiniteCanvasState state,
    Offset localPos,
  ) {
    final worldPos = _localToWorld(localPos, state);
    final delta = (worldPos - state.viewportOffset) * state.zoomLevel;
    context.read<InfiniteCanvasBloc>().add(PanViewport(delta));
  }

  Offset _localToWorld(Offset local, InfiniteCanvasState state) {
    final bounds = _worldBounds(state.nodes.values.toList());
    final scaleX = width / (bounds.width == 0 ? 1 : bounds.width);
    final scaleY = height / (bounds.height == 0 ? 1 : bounds.height);
    final scale = scaleX < scaleY ? scaleX : scaleY;
    return Offset(
      bounds.left + local.dx / scale,
      bounds.top + local.dy / scale,
    );
  }

  static Rect _worldBounds(List<CanvasNode> nodes) {
    if (nodes.isEmpty) return const Rect.fromLTWH(-500, -500, 1000, 1000);
    var b = nodes.first.worldBounds;
    for (final n in nodes) {
      b = b.expandToInclude(n.worldBounds);
    }
    return b.inflate(200);
  }
}

class _MinimapPainter extends CustomPainter {
  const _MinimapPainter({
    required this.nodes,
    required this.viewportOffset,
    required this.zoomLevel,
    required this.screenSize,
    required this.mapSize,
  });

  final Map<String, CanvasNode> nodes;
  final Offset viewportOffset;
  final double zoomLevel;
  final Size screenSize;
  final Size mapSize;

  @override
  void paint(Canvas canvas, Size size) {
    final allNodes = nodes.values.toList();
    final worldBounds = Minimap._worldBounds(allNodes);

    final scaleX = mapSize.width / worldBounds.width;
    final scaleY = mapSize.height / worldBounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    Offset toMap(Offset world) => Offset(
          (world.dx - worldBounds.left) * scale,
          (world.dy - worldBounds.top) * scale,
        );

    // Background.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapSize.width, mapSize.height),
      Paint()..color = const Color(0xFFF5F5F5),
    );

    // Nodes as tiny rectangles.
    final nodePaint = Paint()..color = const Color(0xFF90CAF9);
    for (final node in allNodes) {
      final tl = toMap(node.worldBounds.topLeft);
      final br = toMap(node.worldBounds.bottomRight);
      final rect = Rect.fromPoints(tl, br);
      if (rect.width < 2) {
        canvas.drawCircle(rect.center, 2, nodePaint);
      } else {
        canvas.drawRect(rect, nodePaint);
      }
    }

    // Viewport rectangle.
    if (screenSize != Size.zero) {
      final vpTopLeft = viewportOffset -
          Offset(screenSize.width / 2 / zoomLevel,
              screenSize.height / 2 / zoomLevel);
      final vpBottomRight = viewportOffset +
          Offset(screenSize.width / 2 / zoomLevel,
              screenSize.height / 2 / zoomLevel);
      final vtl = toMap(vpTopLeft);
      final vbr = toMap(vpBottomRight);
      final vpRect = Rect.fromPoints(vtl, vbr);

      canvas.drawRect(
        vpRect,
        Paint()
          ..color = Colors.blue.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        vpRect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.nodes != nodes ||
      old.viewportOffset != viewportOffset ||
      old.zoomLevel != zoomLevel;
}
