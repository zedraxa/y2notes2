import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/graph_bloc.dart';
import '../bloc/graph_event.dart';
import '../bloc/graph_state.dart';
import '../widgets/equation_input_panel.dart';
import '../widgets/graph_canvas_widget.dart';
import '../widgets/matrix_panel.dart';
import '../widgets/variable_panel.dart';

/// Full-screen page for interactive math graph editing.
///
/// Provides a graph canvas with side panels for functions, variables,
/// and matrix operations.
class GraphEditorPage extends StatelessWidget {
  const GraphEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GraphBloc(),
      child: const _GraphEditorBody(),
    );
  }
}

class _GraphEditorBody extends StatefulWidget {
  const _GraphEditorBody();

  @override
  State<_GraphEditorBody> createState() => _GraphEditorBodyState();
}

class _GraphEditorBodyState extends State<_GraphEditorBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Create a default graph on first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      context.read<GraphBloc>().add(GraphCreated(
            bounds: Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
            title: 'Graph',
          ));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Graph'),
        actions: [
          BlocBuilder<GraphBloc, GraphState>(
            builder: (context, state) {
              final graph = state.selectedGraph;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (graph != null) ...[
                    IconButton(
                      icon: Icon(
                        graph.showGrid
                            ? Icons.grid_on
                            : Icons.grid_off,
                      ),
                      tooltip: 'Toggle grid',
                      onPressed: () => context.read<GraphBloc>().add(
                            GraphGridToggled(visible: !graph.showGrid),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out_map),
                      tooltip: 'Reset viewport',
                      onPressed: () =>
                          context.read<GraphBloc>().add(
                                const GraphViewportChanged(
                                  xMin: -10,
                                  xMax: 10,
                                  yMin: -10,
                                  yMax: 10,
                                ),
                              ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Graph canvas ────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: BlocBuilder<GraphBloc, GraphState>(
              builder: (context, state) {
                final graph = state.selectedGraph;
                if (graph == null) {
                  return const Center(
                    child: Text('Tap + to create a graph'),
                  );
                }
                return _InteractiveGraph(graph: graph);
              },
            ),
          ),

          // ── Tabbed panels ──────────────────────────────────────────
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Functions'),
              Tab(text: 'Variables'),
              Tab(text: 'Matrices'),
            ],
          ),
          Expanded(
            flex: 2,
            child: TabBarView(
              controller: _tabController,
              children: const [
                SingleChildScrollView(child: EquationInputPanel()),
                SingleChildScrollView(child: VariablePanel()),
                SingleChildScrollView(child: MatrixPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive graph widget that supports pinch-to-zoom and pan.
class _InteractiveGraph extends StatelessWidget {
  const _InteractiveGraph({required this.graph});

  final dynamic graph; // GraphElement

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleUpdate: (details) {
            if (details.scale != 1.0) {
              _handleZoom(context, details.scale);
            } else {
              _handlePan(context, details.focalPointDelta, constraints);
            }
          },
          child: GraphCanvasWidget(graph: graph),
        );
      },
    );
  }

  void _handleZoom(BuildContext context, double scale) {
    final bloc = context.read<GraphBloc>();
    final g = bloc.state.selectedGraph;
    if (g == null) return;

    final factor = 1.0 / scale;
    final cx = (g.xMin + g.xMax) / 2;
    final cy = (g.yMin + g.yMax) / 2;
    final hw = g.xRange / 2 * factor;
    final hh = g.yRange / 2 * factor;

    bloc.add(GraphViewportChanged(
      xMin: cx - hw,
      xMax: cx + hw,
      yMin: cy - hh,
      yMax: cy + hh,
    ));
  }

  void _handlePan(
      BuildContext context, Offset delta, BoxConstraints constraints) {
    final bloc = context.read<GraphBloc>();
    final g = bloc.state.selectedGraph;
    if (g == null) return;

    final dx = -delta.dx / constraints.maxWidth * g.xRange;
    final dy = delta.dy / constraints.maxHeight * g.yRange;

    bloc.add(GraphViewportChanged(
      xMin: g.xMin + dx,
      xMax: g.xMax + dx,
      yMin: g.yMin + dy,
      yMax: g.yMax + dy,
    ));
  }
}
