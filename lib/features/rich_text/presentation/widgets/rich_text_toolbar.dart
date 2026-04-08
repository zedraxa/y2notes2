import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_node.dart';
import '../bloc/rich_text_bloc.dart';
import '../bloc/rich_text_event.dart';
import '../bloc/rich_text_state.dart';

/// Predefined text colours for the colour picker.
const _textColors = <Color>[
  Colors.black,
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
  Colors.grey,
];

/// Floating toolbar that provides formatting controls for the
/// currently selected rich text element.
class RichTextToolbar extends StatelessWidget {
  const RichTextToolbar({super.key});

  /// Current active styles from the first span of the first
  /// node – used to highlight active buttons.
  Set<InlineStyle> _activeStyles(RichTextState state) {
    final el = state.selectedElement;
    if (el == null || el.nodes.isEmpty) return const {};
    final firstNode = el.nodes.first;
    if (firstNode.spans.isEmpty) return const {};
    return firstNode.spans.first.styles;
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RichTextBloc, RichTextState>(
        builder: (context, state) {
          if (state.selectedElement == null) {
            return const SizedBox.shrink();
          }

          final active = _activeStyles(state);

          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Undo
                  _UndoRedoButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                    enabled: state.canUndo,
                    onPressed: () =>
                        context.read<RichTextBloc>().add(
                              const UndoRichText(),
                            ),
                  ),
                  // Redo
                  _UndoRedoButton(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                    enabled: state.canRedo,
                    onPressed: () =>
                        context.read<RichTextBloc>().add(
                              const RedoRichText(),
                            ),
                  ),
                  const _ToolbarDivider(),
                  // Heading dropdown
                  _HeadingDropdown(
                    elementId:
                        state.selectedElement!.id,
                  ),
                  const _ToolbarDivider(),
                  // Bold
                  _StyleButton(
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    style: InlineStyle.bold,
                    elementId:
                        state.selectedElement!.id,
                    isActive: active.contains(
                      InlineStyle.bold,
                    ),
                  ),
                  // Italic
                  _StyleButton(
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    style: InlineStyle.italic,
                    elementId:
                        state.selectedElement!.id,
                    isActive: active.contains(
                      InlineStyle.italic,
                    ),
                  ),
                  // Underline
                  _StyleButton(
                    icon: Icons.format_underlined,
                    tooltip: 'Underline',
                    style: InlineStyle.underline,
                    elementId:
                        state.selectedElement!.id,
                    isActive: active.contains(
                      InlineStyle.underline,
                    ),
                  ),
                  // Strikethrough
                  _StyleButton(
                    icon: Icons.strikethrough_s,
                    tooltip: 'Strikethrough',
                    style: InlineStyle.strikethrough,
                    elementId:
                        state.selectedElement!.id,
                    isActive: active.contains(
                      InlineStyle.strikethrough,
                    ),
                  ),
                  // Inline code
                  _StyleButton(
                    icon: Icons.code,
                    tooltip: 'Inline Code',
                    style: InlineStyle.code,
                    elementId:
                        state.selectedElement!.id,
                    isActive: active.contains(
                      InlineStyle.code,
                    ),
                  ),
                  // Highlight
                  _StyleButton(
                    icon: Icons.highlight,
                    tooltip: 'Highlight',
                    style: InlineStyle.highlight,
                    elementId:
                        state.selectedElement!.id,
                    isActive: active.contains(
                      InlineStyle.highlight,
                    ),
                  ),
                  const _ToolbarDivider(),
                  // Text colour picker
                  _TextColorButton(
                    elementId:
                        state.selectedElement!.id,
                  ),
                  const _ToolbarDivider(),
                  // Insert code block
                  _InsertButton(
                    icon: Icons.data_object,
                    tooltip: 'Code Block',
                    elementId:
                        state.selectedElement!.id,
                    nodeType: RichTextNodeType.codeBlock,
                  ),
                  // Insert table
                  _InsertButton(
                    icon: Icons.table_chart_outlined,
                    tooltip: 'Table',
                    elementId:
                        state.selectedElement!.id,
                    nodeType: RichTextNodeType.table,
                  ),
                  // Insert unordered list
                  _InsertButton(
                    icon:
                        Icons.format_list_bulleted,
                    tooltip: 'Bullet List',
                    elementId:
                        state.selectedElement!.id,
                    nodeType:
                        RichTextNodeType.unorderedList,
                  ),
                  // Insert ordered list
                  _InsertButton(
                    icon:
                        Icons.format_list_numbered,
                    tooltip: 'Numbered List',
                    elementId:
                        state.selectedElement!.id,
                    nodeType:
                        RichTextNodeType.orderedList,
                  ),
                  // Insert blockquote
                  _InsertButton(
                    icon: Icons.format_quote,
                    tooltip: 'Quote',
                    elementId:
                        state.selectedElement!.id,
                    nodeType:
                        RichTextNodeType.blockquote,
                  ),
                  // Insert divider
                  _InsertButton(
                    icon: Icons.horizontal_rule,
                    tooltip: 'Divider',
                    elementId:
                        state.selectedElement!.id,
                    nodeType:
                        RichTextNodeType.divider,
                  ),
                ],
              ),
            ),
          );
        },
      );
}

// ── Undo / Redo button ────────────────────────────────────────

class _UndoRedoButton extends StatelessWidget {
  const _UndoRedoButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: enabled
              ? null
              : Theme.of(context).disabledColor,
        ),
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
      );
}

// ── Heading dropdown ──────────────────────────────────────────

class _HeadingDropdown extends StatelessWidget {
  const _HeadingDropdown({required this.elementId});
  final String elementId;

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<int>(
        tooltip: 'Heading Level',
        icon: const Icon(Icons.title, size: 20),
        onSelected: (level) {
          context.read<RichTextBloc>().add(
                ChangeHeadingLevel(
                  elementId: elementId,
                  nodeIndex: 0,
                  level: level,
                ),
              );
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 0,
            child: Text('Paragraph'),
          ),
          const PopupMenuItem(
            value: 1,
            child: Text(
              'Heading 1',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 2,
            child: Text(
              'Heading 2',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 3,
            child: Text(
              'Heading 3',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 4,
            child: Text(
              'Heading 4',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 5,
            child: Text(
              'Heading 5',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 6,
            child: Text(
              'Heading 6',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
}

// ── Inline style toggle with active state ─────────────────────

class _StyleButton extends StatelessWidget {
  const _StyleButton({
    required this.icon,
    required this.tooltip,
    required this.style,
    required this.elementId,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final InlineStyle style;
  final String elementId;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: isActive
          ? BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isActive ? colorScheme.primary : null,
        ),
        tooltip: tooltip,
        onPressed: () {
          context.read<RichTextBloc>().add(
                ToggleInlineStyle(
                  elementId: elementId,
                  nodeIndex: 0,
                  spanIndex: 0,
                  style: style,
                ),
              );
        },
      ),
    );
  }
}

// ── Text colour picker button ─────────────────────────────────

class _TextColorButton extends StatelessWidget {
  const _TextColorButton({required this.elementId});
  final String elementId;

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<Color?>(
        tooltip: 'Text Colour',
        icon: const Icon(
          Icons.format_color_text,
          size: 20,
        ),
        onSelected: (color) {
          context.read<RichTextBloc>().add(
                SetSpanColor(
                  elementId: elementId,
                  nodeIndex: 0,
                  spanIndex: 0,
                  color: color,
                ),
              );
        },
        itemBuilder: (_) => [
          // "Default" entry to clear colour
          const PopupMenuItem<Color?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.format_color_reset, size: 18),
                SizedBox(width: 8),
                Text('Default'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // Colour grid
          PopupMenuItem<Color?>(
            enabled: false,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _textColors
                  .map(
                    (c) => _ColorSwatch(
                      color: c,
                      onTap: () {
                        Navigator.pop(context);
                        context
                            .read<RichTextBloc>()
                            .add(
                              SetSpanColor(
                                elementId: elementId,
                                nodeIndex: 0,
                                spanIndex: 0,
                                color: c,
                              ),
                            );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ),
      );
}

// ── Insert block button ───────────────────────────────────────

class _InsertButton extends StatelessWidget {
  const _InsertButton({
    required this.icon,
    required this.tooltip,
    required this.elementId,
    required this.nodeType,
  });

  final IconData icon;
  final String tooltip;
  final String elementId;
  final RichTextNodeType nodeType;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: () {
          final bloc = context.read<RichTextBloc>();
          final element = bloc.state.selectedElement;
          if (element == null) return;

          final node = _createDefaultNode(nodeType);
          bloc.add(InsertNode(
            elementId: elementId,
            index: element.nodes.length,
            node: node,
          ));
        },
      );

  RichTextNode _createDefaultNode(
    RichTextNodeType type,
  ) {
    switch (type) {
      case RichTextNodeType.codeBlock:
        return const RichTextNode(
          type: RichTextNodeType.codeBlock,
          codeText: '',
        );
      case RichTextNodeType.table:
        return const RichTextNode(
          type: RichTextNodeType.table,
          tableData: [
            ['Header 1', 'Header 2', 'Header 3'],
            ['', '', ''],
          ],
        );
      case RichTextNodeType.unorderedList:
        return const RichTextNode(
          type: RichTextNodeType.unorderedList,
          children: [
            RichTextNode(
              type: RichTextNodeType.paragraph,
              spans: [RichTextSpan(text: '')],
            ),
          ],
        );
      case RichTextNodeType.orderedList:
        return const RichTextNode(
          type: RichTextNodeType.orderedList,
          children: [
            RichTextNode(
              type: RichTextNodeType.paragraph,
              spans: [RichTextSpan(text: '')],
            ),
          ],
        );
      case RichTextNodeType.blockquote:
        return const RichTextNode(
          type: RichTextNodeType.blockquote,
          spans: [RichTextSpan(text: '')],
        );
      case RichTextNodeType.divider:
        return const RichTextNode(
          type: RichTextNodeType.divider,
        );
      case RichTextNodeType.heading:
        return const RichTextNode(
          type: RichTextNodeType.heading,
          headingLevel: 2,
          spans: [RichTextSpan(text: '')],
        );
      case RichTextNodeType.paragraph:
        return const RichTextNode(
          type: RichTextNodeType.paragraph,
          spans: [RichTextSpan(text: '')],
        );
    }
  }
}

// ── Toolbar divider ───────────────────────────────────────────

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        child: SizedBox(
          height: 24,
          child: VerticalDivider(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
      );
}
