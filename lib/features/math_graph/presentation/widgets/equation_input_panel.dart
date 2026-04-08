import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/graph_style.dart';
import '../../domain/models/graph_type.dart';
import '../bloc/graph_bloc.dart';
import '../bloc/graph_event.dart';
import '../bloc/graph_state.dart';

/// Panel for adding, editing, and removing function equations.
class EquationInputPanel extends StatefulWidget {
  const EquationInputPanel({super.key});

  @override
  State<EquationInputPanel> createState() => _EquationInputPanelState();
}

class _EquationInputPanelState extends State<EquationInputPanel> {
  final _controller = TextEditingController();
  GraphType _selectedType = GraphType.line;

  static const _defaultColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addFunction() {
    final expr = _controller.text.trim();
    if (expr.isEmpty) return;

    final bloc = context.read<GraphBloc>();
    final graph = bloc.state.selectedGraph;
    final colorIndex =
        (graph?.functions.length ?? 0) % _defaultColors.length;

    bloc.add(FunctionAdded(
      expression: expr,
      type: _selectedType,
      style: GraphStyle(color: _defaultColors[colorIndex]),
    ));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GraphBloc, GraphState>(
      builder: (context, state) {
        final graph = state.selectedGraph;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Add function input ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'e.g. sin(x), x^2+1, cos(t);sin(t)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _addFunction(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<GraphType>(
                    value: _selectedType,
                    isDense: true,
                    items: GraphType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedType = v);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    tooltip: 'Add function',
                    onPressed: _addFunction,
                  ),
                ],
              ),
            ),

            // ── Function list ───────────────────────────────────────
            if (graph != null)
              ...graph.functions.map((func) => ListTile(
                    dense: true,
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: func.style.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      func.label ?? func.expression,
                      style: TextStyle(
                        decoration:
                            func.isVisible ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: func.hasError
                        ? Text(
                            func.errorMessage!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 11),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            func.isVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 18,
                          ),
                          onPressed: () => context
                              .read<GraphBloc>()
                              .add(FunctionVisibilityToggled(func.id)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => context
                              .read<GraphBloc>()
                              .add(FunctionRemoved(func.id)),
                        ),
                      ],
                    ),
                  )),
          ],
        );
      },
    );
  }
}
