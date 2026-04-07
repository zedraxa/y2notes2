import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/graph_bloc.dart';
import '../bloc/graph_event.dart';
import '../bloc/graph_state.dart';

/// Panel for managing user-defined variables with optional sliders.
class VariablePanel extends StatefulWidget {
  const VariablePanel({super.key});

  @override
  State<VariablePanel> createState() => _VariablePanelState();
}

class _VariablePanelState extends State<VariablePanel> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addVariable() {
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text.trim());
    if (name.isEmpty || value == null) return;

    context.read<GraphBloc>().add(VariableSet(
          name: name,
          value: value,
          min: -10,
          max: 10,
          step: 0.1,
        ));
    _nameController.clear();
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GraphBloc, GraphState>(
      builder: (context, state) {
        final graph = state.selectedGraph;
        final variables = graph?.variables ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Add variable ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'a',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('='),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      onSubmitted: (_) => _addVariable(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 20),
                    tooltip: 'Add variable',
                    onPressed: _addVariable,
                  ),
                ],
              ),
            ),

            // ── Variable list with sliders ──────────────────────────
            ...variables.map((v) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${v.name} =',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (v.hasRange)
                        Expanded(
                          child: Slider(
                            value: v.value.clamp(v.min!, v.max!),
                            min: v.min!,
                            max: v.max!,
                            divisions: v.step != null
                                ? ((v.max! - v.min!) / v.step!).round()
                                : null,
                            label: v.value.toStringAsFixed(2),
                            onChanged: (val) {
                              context.read<GraphBloc>().add(VariableSet(
                                    name: v.name,
                                    value: val,
                                    min: v.min,
                                    max: v.max,
                                    step: v.step,
                                  ));
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Text(v.value.toStringAsFixed(2)),
                        ),
                      Text(
                        v.value.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => context
                            .read<GraphBloc>()
                            .add(VariableRemoved(v.name)),
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
