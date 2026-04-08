import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/matrix_data.dart';
import '../bloc/graph_bloc.dart';
import '../bloc/graph_event.dart';
import '../bloc/graph_state.dart';

/// Panel for creating, editing, and performing operations on matrices.
class MatrixPanel extends StatelessWidget {
  const MatrixPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GraphBloc, GraphState>(
      builder: (context, state) {
        final graph = state.selectedGraph;
        final matrices = graph?.matrices ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Add matrix button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text('Matrices',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _MatrixSizeButton(
                    label: '2×2',
                    onTap: () => _addMatrix(context, 2),
                  ),
                  const SizedBox(width: 4),
                  _MatrixSizeButton(
                    label: '3×3',
                    onTap: () => _addMatrix(context, 3),
                  ),
                  const SizedBox(width: 4),
                  _MatrixSizeButton(
                    label: '4×4',
                    onTap: () => _addMatrix(context, 4),
                  ),
                ],
              ),
            ),

            // ── Matrix editors ───────────────────────────────────────
            for (var i = 0; i < matrices.length; i++) ...[
              _MatrixEditor(
                matrix: matrices[i],
                index: i,
                label: matrices[i].label ?? 'M${i + 1}',
              ),
              const Divider(height: 1),
            ],

            // ── Operations ────────────────────────────────────────────
            if (matrices.length >= 2) ...[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _OpButton(
                      label: 'A + B',
                      onTap: () => _doOp(context, 'add', [0, 1]),
                    ),
                    _OpButton(
                      label: 'A - B',
                      onTap: () => _doOp(context, 'subtract', [0, 1]),
                    ),
                    _OpButton(
                      label: 'A × B',
                      onTap: () => _doOp(context, 'multiply', [0, 1]),
                    ),
                  ],
                ),
              ),
            ],
            if (matrices.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _OpButton(
                      label: 'Aᵀ',
                      onTap: () => _doOp(context, 'transpose', [0]),
                    ),
                    _OpButton(
                      label: 'det(A)',
                      onTap: () => _doOp(context, 'determinant', [0]),
                    ),
                    _OpButton(
                      label: 'A⁻¹',
                      onTap: () => _doOp(context, 'inverse', [0]),
                    ),
                    _OpButton(
                      label: 'tr(A)',
                      onTap: () => _doOp(context, 'trace', [0]),
                    ),
                  ],
                ),
              ),
            ],

            // ── Result display ─────────────────────────────────────────
            if (state.matrixResultLabel != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result: ${state.matrixResultLabel}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (state.scalarResult != null)
                      Text(
                        state.scalarResult!.toStringAsFixed(4),
                        style: const TextStyle(fontSize: 18),
                      ),
                    if (state.matrixResult != null)
                      _MatrixDisplay(matrix: state.matrixResult!),
                  ],
                ),
              ),

            // ── Error ─────────────────────────────────────────────────
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _addMatrix(BuildContext context, int size) {
    final count = context.read<GraphBloc>().state.selectedGraph?.matrices.length ?? 0;
    final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final label = count < labels.length ? labels[count] : 'M${count + 1}';
    context.read<GraphBloc>().add(MatrixAdded(
          matrix: MatrixData.identity(size, label: label),
        ));
  }

  void _doOp(BuildContext context, String op, List<int> indices) {
    context.read<GraphBloc>().add(MatrixOperationRequested(
          operation: op,
          operandIndices: indices,
        ));
  }
}

// ─── Private helper widgets ───────────────────────────────────────────────────

class _MatrixSizeButton extends StatelessWidget {
  const _MatrixSizeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _OpButton extends StatelessWidget {
  const _OpButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MatrixEditor extends StatelessWidget {
  const _MatrixEditor({
    required this.matrix,
    required this.index,
    required this.label,
  });

  final MatrixData matrix;
  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    context.read<GraphBloc>().add(MatrixRemoved(index)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Table(
            defaultColumnWidth: const FixedColumnWidth(56),
            children: List.generate(
              matrix.rows,
              (row) => TableRow(
                children: List.generate(
                  matrix.cols,
                  (col) => _MatrixCell(
                    value: matrix.at(row, col),
                    onChanged: (v) {
                      context.read<GraphBloc>().add(MatrixCellUpdated(
                            matrixIndex: index,
                            row: row,
                            col: col,
                            value: v,
                          ));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixCell extends StatefulWidget {
  const _MatrixCell({required this.value, required this.onChanged});
  final double value;
  final void Function(double) onChanged;

  @override
  State<_MatrixCell> createState() => _MatrixCellState();
}

class _MatrixCellState extends State<_MatrixCell> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(_MatrixCell old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(
            signed: true, decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        ),
        onSubmitted: (text) {
          final v = double.tryParse(text);
          if (v != null) widget.onChanged(v);
        },
      ),
    );
  }
}

class _MatrixDisplay extends StatelessWidget {
  const _MatrixDisplay({required this.matrix});
  final MatrixData matrix;

  String _format(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: List.generate(
        matrix.rows,
        (row) => TableRow(
          children: List.generate(
            matrix.cols,
            (col) => Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                _format(matrix.at(row, col)),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
