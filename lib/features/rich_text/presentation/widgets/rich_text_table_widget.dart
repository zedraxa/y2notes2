import 'package:flutter/material.dart';

import '../../domain/entities/rich_text_node.dart';

/// Renders an editable table from [RichTextNode.tableData].
class RichTextTableWidget extends StatelessWidget {
  const RichTextTableWidget({
    required this.node,
    required this.onCellChanged,
    required this.onAddRow,
    required this.onAddColumn,
    this.isEditing = false,
    super.key,
  });

  final RichTextNode node;
  final void Function(int row, int col, String value)
      onCellChanged;
  final VoidCallback onAddRow;
  final VoidCallback onAddColumn;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final data = node.tableData;
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table grid
        Table(
          border: TableBorder.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
          defaultVerticalAlignment:
              TableCellVerticalAlignment.middle,
          children: [
            for (var row = 0;
                row < data.length;
                row++)
              TableRow(
                decoration: row == 0
                    ? BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.5),
                      )
                    : null,
                children: [
                  for (var col = 0;
                      col < data[row].length;
                      col++)
                    _TableCell(
                      value: data[row][col],
                      isHeader: row == 0,
                      isEditing: isEditing,
                      onChanged: (v) =>
                          onCellChanged(row, col, v),
                    ),
                ],
              ),
          ],
        ),

        // Add row / column buttons (only in edit mode)
        if (isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onAddRow,
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                  ),
                  label: const Text(
                    'Row',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onAddColumn,
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                  ),
                  label: const Text(
                    'Column',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Individual table cell ─────────────────────────────────────

class _TableCell extends StatefulWidget {
  const _TableCell({
    required this.value,
    required this.isHeader,
    required this.isEditing,
    required this.onChanged,
  });

  final String value;
  final bool isHeader;
  final bool isEditing;
  final ValueChanged<String> onChanged;

  @override
  State<_TableCell> createState() => _TableCellState();
}

class _TableCellState extends State<_TableCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TableCell old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 4,
        ),
        child: widget.isEditing
            ? TextField(
                controller: _controller,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isHeader
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
              )
            : Text(
                widget.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isHeader
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
      );
}
