import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_element.dart';
import '../bloc/rich_text_bloc.dart';
import '../bloc/rich_text_event.dart';
import '../bloc/rich_text_state.dart';
import 'rich_text_node_widget.dart';
import 'rich_text_toolbar.dart';

/// Full-screen rich text editor page.
///
/// Opens from the canvas when the user taps a
/// [RichTextElement] or creates a new one via the toolbar.
class RichTextEditorPage extends StatelessWidget {
  const RichTextEditorPage({
    required this.elementId,
    super.key,
  });

  final String elementId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RichTextBloc, RichTextState>(
        builder: (context, state) {
          final element =
              state.elements.cast<RichTextElement?>().firstWhere(
                    (e) => e?.id == elementId,
                    orElse: () => null,
                  );

          if (element == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Rich Text'),
              ),
              body: const Center(
                child: Text('Element not found.'),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Rich Text Editor'),
              actions: [
                // Markdown preview toggle
                IconButton(
                  icon: const Icon(Icons.preview),
                  tooltip: 'View Markdown',
                  onPressed: () {
                    _showMarkdownPreview(
                      context,
                      element,
                    );
                  },
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () {
                    context.read<RichTextBloc>().add(
                          DeleteRichTextElement(
                            elementId: elementId,
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Formatting toolbar
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RichTextToolbar(),
                  ),
                ),
                const Divider(height: 1),
                // Node list
                Expanded(
                  child: _NodeListEditor(
                    element: element,
                  ),
                ),
              ],
            ),
          );
        },
      );

  void _showMarkdownPreview(
    BuildContext context,
    RichTextElement element,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Markdown'),
        content: SingleChildScrollView(
          child: SelectableText(
            element.markdown,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Node list editor ─────────────────────────────────────────

class _NodeListEditor extends StatelessWidget {
  const _NodeListEditor({required this.element});
  final RichTextElement element;

  @override
  Widget build(BuildContext context) =>
      ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: element.nodes.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == element.nodes.length) {
            return _AddNodeButton(
              elementId: element.id,
              insertIndex: index,
            );
          }

          return Dismissible(
            key: ValueKey(
              '${element.id}_node_$index',
            ),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding:
                  const EdgeInsets.only(right: 16),
              color: Colors.red.withOpacity(0.1),
              child: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
            onDismissed: (_) {
              context.read<RichTextBloc>().add(
                    RemoveNode(
                      elementId: element.id,
                      index: index,
                    ),
                  );
            },
            child: RichTextNodeWidget(
              node: element.nodes[index],
              nodeIndex: index,
              element: element,
              isEditing: element.isEditing,
            ),
          );
        },
      );
}

// ── Add node button ──────────────────────────────────────────

class _AddNodeButton extends StatelessWidget {
  const _AddNodeButton({
    required this.elementId,
    required this.insertIndex,
  });

  final String elementId;
  final int insertIndex;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: () {
            context.read<RichTextBloc>().add(
                  InsertNode(
                    elementId: elementId,
                    index: insertIndex,
                    node: const RichTextNode(
                      type: RichTextNodeType.paragraph,
                      spans: [
                        RichTextSpan(text: ''),
                      ],
                    ),
                  ),
                );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Block'),
        ),
      );
}
