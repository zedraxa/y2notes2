import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_node.dart';
import '../bloc/rich_text_bloc.dart';
import '../bloc/rich_text_event.dart';
import '../bloc/rich_text_state.dart';

/// Floating toolbar that provides formatting controls for the
/// currently selected rich text element.
class RichTextToolbar extends StatelessWidget {
  const RichTextToolbar({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RichTextBloc, RichTextState>(
        builder: (context, state) {
          if (state.selectedElement == null) {
            return const SizedBox.shrink();
          }

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
                  ),
                  // Italic
                  _StyleButton(
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    style: InlineStyle.italic,
                    elementId:
                        state.selectedElement!.id,
                  ),
                  // Underline
                  _StyleButton(
                    icon: Icons.format_underlined,
                    tooltip: 'Underline',
                    style: InlineStyle.underline,
                    elementId:
                        state.selectedElement!.id,
                  ),
                  // Strikethrough
                  _StyleButton(
                    icon: Icons.strikethrough_s,
                    tooltip: 'Strikethrough',
                    style: InlineStyle.strikethrough,
                    elementId:
                        state.selectedElement!.id,
                  ),
                  // Inline code
                  _StyleButton(
                    icon: Icons.code,
                    tooltip: 'Inline Code',
                    style: InlineStyle.code,
                    elementId:
                        state.selectedElement!.id,
                  ),
                  // Highlight
                  _StyleButton(
                    icon: Icons.highlight,
                    tooltip: 'Highlight',
                    style: InlineStyle.highlight,
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

// ── Inline style toggle ───────────────────────────────────────

class _StyleButton extends StatelessWidget {
  const _StyleButton({
    required this.icon,
    required this.tooltip,
    required this.style,
    required this.elementId,
  });

  final IconData icon;
  final String tooltip;
  final InlineStyle style;
  final String elementId;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 20),
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
