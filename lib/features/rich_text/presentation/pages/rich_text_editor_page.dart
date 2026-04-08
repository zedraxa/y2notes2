import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_element.dart';
import '../../domain/entities/rich_text_node.dart';
import '../bloc/rich_text_bloc.dart';
import '../bloc/rich_text_event.dart';
import '../bloc/rich_text_state.dart';
import '../widgets/rich_text_node_widget.dart';
import '../widgets/rich_text_toolbar.dart';

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

          return _EditorShortcuts(
            elementId: elementId,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Rich Text Editor'),
                actions: [
                  // Find & replace
                  IconButton(
                    icon: const Icon(Icons.find_replace),
                    tooltip: 'Find & Replace',
                    onPressed: () {
                      _showFindReplaceDialog(
                        context,
                        element,
                      );
                    },
                  ),
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
                  // Find results banner
                  if (state.findQuery.isNotEmpty)
                    _FindBanner(
                      query: state.findQuery,
                      matchCount: state.findMatchCount,
                    ),
                  // Node list
                  Expanded(
                    child: _NodeListEditor(
                      element: element,
                    ),
                  ),
                  // Word & character count
                  _WordCountBar(element: element),
                ],
              ),
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

  void _showFindReplaceDialog(
    BuildContext context,
    RichTextElement element,
  ) {
    showDialog(
      context: context,
      builder: (_) => _FindReplaceDialog(
        elementId: element.id,
        bloc: context.read<RichTextBloc>(),
      ),
    );
  }
}

// ── Keyboard shortcuts wrapper ───────────────────────────────

class _EditorShortcuts extends StatelessWidget {
  const _EditorShortcuts({
    required this.elementId,
    required this.child,
  });

  final String elementId;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyB,
          ): const _ToggleStyleIntent(InlineStyle.bold),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.keyB,
          ): const _ToggleStyleIntent(InlineStyle.bold),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyI,
          ): const _ToggleStyleIntent(InlineStyle.italic),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.keyI,
          ): const _ToggleStyleIntent(InlineStyle.italic),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyU,
          ): const _ToggleStyleIntent(
            InlineStyle.underline,
          ),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.keyU,
          ): const _ToggleStyleIntent(
            InlineStyle.underline,
          ),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyZ,
          ): const _UndoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.keyZ,
          ): const _UndoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyY,
          ): const _RedoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyZ,
          ): const _RedoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyH,
          ): const _FindReplaceIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.keyH,
          ): const _FindReplaceIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _ToggleStyleIntent:
                CallbackAction<_ToggleStyleIntent>(
              onInvoke: (intent) {
                context.read<RichTextBloc>().add(
                      ToggleInlineStyle(
                        elementId: elementId,
                        nodeIndex: 0,
                        spanIndex: 0,
                        style: intent.style,
                      ),
                    );
                return null;
              },
            ),
            _UndoIntent: CallbackAction<_UndoIntent>(
              onInvoke: (_) {
                context.read<RichTextBloc>().add(
                      const UndoRichText(),
                    );
                return null;
              },
            ),
            _RedoIntent: CallbackAction<_RedoIntent>(
              onInvoke: (_) {
                context.read<RichTextBloc>().add(
                      const RedoRichText(),
                    );
                return null;
              },
            ),
            _FindReplaceIntent:
                CallbackAction<_FindReplaceIntent>(
              onInvoke: (_) {
                final state =
                    context.read<RichTextBloc>().state;
                final el = state.selectedElement;
                if (el != null) {
                  showDialog(
                    context: context,
                    builder: (_) => _FindReplaceDialog(
                      elementId: el.id,
                      bloc: context.read<RichTextBloc>(),
                    ),
                  );
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: child,
          ),
        ),
      );
}

class _ToggleStyleIntent extends Intent {
  const _ToggleStyleIntent(this.style);
  final InlineStyle style;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _FindReplaceIntent extends Intent {
  const _FindReplaceIntent();
}

// ── Find results banner ──────────────────────────────────────

class _FindBanner extends StatelessWidget {
  const _FindBanner({
    required this.query,
    required this.matchCount,
  });

  final String query;
  final int matchCount;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withOpacity(0.3),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16),
            const SizedBox(width: 8),
            Text(
              '"$query" — $matchCount '
              '${matchCount == 1 ? 'match' : 'matches'}',
              style: const TextStyle(fontSize: 13),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context
                  .read<RichTextBloc>()
                  .add(const ClearFind()),
              child: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      );
}

// ── Find & Replace dialog ────────────────────────────────────

class _FindReplaceDialog extends StatefulWidget {
  const _FindReplaceDialog({
    required this.elementId,
    required this.bloc,
  });

  final String elementId;
  final RichTextBloc bloc;

  @override
  State<_FindReplaceDialog> createState() =>
      _FindReplaceDialogState();
}

class _FindReplaceDialogState
    extends State<_FindReplaceDialog> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Find & Replace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _findController,
              decoration: const InputDecoration(
                labelText: 'Find',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                widget.bloc.add(
                  FindInRichText(query: query),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _replaceController,
              decoration: const InputDecoration(
                labelText: 'Replace with',
                prefixIcon:
                    Icon(Icons.find_replace),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.bloc.add(const ClearFind());
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              if (_findController.text.isNotEmpty) {
                widget.bloc.add(
                  ReplaceInRichText(
                    elementId: widget.elementId,
                    query: _findController.text,
                    replacement:
                        _replaceController.text,
                  ),
                );
              }
            },
            child: const Text('Replace'),
          ),
          FilledButton(
            onPressed: () {
              if (_findController.text.isNotEmpty) {
                widget.bloc.add(
                  ReplaceInRichText(
                    elementId: widget.elementId,
                    query: _findController.text,
                    replacement:
                        _replaceController.text,
                    replaceAll: true,
                  ),
                );
              }
            },
            child: const Text('Replace All'),
          ),
        ],
      );
}

// ── Word & character count bar ───────────────────────────────

class _WordCountBar extends StatelessWidget {
  const _WordCountBar({required this.element});
  final RichTextElement element;

  @override
  Widget build(BuildContext context) {
    final text = element.plainText;
    final charCount = text.length;
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Text(
        '$wordCount ${wordCount == 1 ? 'word' : 'words'}'
        '  ·  '
        '$charCount ${charCount == 1 ? 'character' : 'characters'}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).hintColor,
        ),
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
