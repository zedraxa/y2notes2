import 'package:flutter/material.dart';

import '../../domain/entities/graph_element.dart';
import '../../engine/graph_renderer.dart';

/// Custom painter that renders a [GraphElement] on the canvas.
class GraphCanvasPainter extends CustomPainter {
  const GraphCanvasPainter({required this.graph});

  final GraphElement graph;

  static const _renderer = GraphRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    // Map the graph to fill the full available size.
    final adjusted = graph.copyWith(
      bounds: Offset.zero & size,
    );
    _renderer.render(canvas, adjusted);
  }

  @override
  bool shouldRepaint(covariant GraphCanvasPainter old) =>
      graph != old.graph;
}

/// Widget that displays a graph element using a CustomPaint layer.
class GraphCanvasWidget extends StatelessWidget {
  const GraphCanvasWidget({
    super.key,
    required this.graph,
    this.onPanUpdate,
    this.onScaleUpdate,
  });

  final GraphElement graph;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(ScaleUpdateDetails)? onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: onScaleUpdate,
      child: CustomPaint(
        painter: GraphCanvasPainter(graph: graph),
        size: Size.infinite,
      ),
    );
  }
}
