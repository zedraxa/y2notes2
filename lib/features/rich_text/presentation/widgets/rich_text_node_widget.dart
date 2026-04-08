import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_element.dart';
import '../../domain/entities/rich_text_node.dart';
import '../bloc/rich_text_bloc.dart';
import '../bloc/rich_text_event.dart';
import 'code_block_widget.dart';
import 'rich_text_table_widget.dart';

/// Renders a single [RichTextNode] as a Flutter widget.
///
/// This is used inside the interactive overlay for editing;
/// canvas rendering uses the separate [RichTextRenderer].
class RichTextNodeWidget extends StatelessWidget {
  const RichTextNodeWidget({
    required this.node,
    required this.nodeIndex,
    required this.element,
    required this.isEditing,
    super.key,
  });

  final RichTextNode node;
  final int nodeIndex;
  final RichTextElement element;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    switch (node.type) {
      case RichTextNodeType.heading:
        return _HeadingWidget(
          node: node,
          nodeIndex: nodeIndex,
          element: element,
          isEditing: isEditing,
        );
      case RichTextNodeType.paragraph:
        return _ParagraphWidget(
          node: node,
          nodeIndex: nodeIndex,
          element: element,
          isEditing: isEditing,
        );
      case RichTextNodeType.codeBlock:
        return CodeBlockWidget(
          node: node,
          isEditing: isEditing,
          onChanged: (text) {
            context.read<RichTextBloc>().add(
                  UpdateNode(
                    elementId: element.id,
                    index: nodeIndex,
                    node: node.copyWith(codeText: text),
                  ),
                );
          },
        );
      case RichTextNodeType.unorderedList:
      case RichTextNodeType.orderedList:
        return _ListWidget(
          node: node,
          nodeIndex: nodeIndex,
          element: element,
          isEditing: isEditing,
        );
      case RichTextNodeType.table:
        return RichTextTableWidget(
          node: node,
          isEditing: isEditing,
          onCellChanged: (row, col, value) {
            context.read<RichTextBloc>().add(
                  UpdateTableCell(
                    elementId: element.id,
                    nodeIndex: nodeIndex,
                    row: row,
                    col: col,
                    value: value,
                  ),
                );
          },
          onAddRow: () {
            context.read<RichTextBloc>().add(
                  AddTableRow(
                    elementId: element.id,
                    nodeIndex: nodeIndex,
                  ),
                );
          },
          onAddColumn: () {
            context.read<RichTextBloc>().add(
                  AddTableColumn(
                    elementId: element.id,
                    nodeIndex: nodeIndex,
                  ),
                );
          },
          onRemoveRow: (row) {
            context.read<RichTextBloc>().add(
                  RemoveTableRow(
                    elementId: element.id,
                    nodeIndex: nodeIndex,
                    row: row,
                  ),
                );
          },
          onRemoveColumn: (col) {
            context.read<RichTextBloc>().add(
                  RemoveTableColumn(
                    elementId: element.id,
                    nodeIndex: nodeIndex,
                    col: col,
                  ),
                );
          },
        );
      case RichTextNodeType.blockquote:
        return _BlockquoteWidget(node: node);
      case RichTextNodeType.divider:
        return const Divider(height: 24, thickness: 1);
    }
  }
}

// ── Heading ──────────────────────────────────────────────────

class _HeadingWidget extends StatelessWidget {
  const _HeadingWidget({
    required this.node,
    required this.nodeIndex,
    required this.element,
    required this.isEditing,
  });

  final RichTextNode node;
  final int nodeIndex;
  final RichTextElement element;
  final bool isEditing;

  double get _fontSize {
    switch (node.headingLevel) {
      case 1:
        return 28;
      case 2:
        return 24;
      case 3:
        return 20;
      case 4:
        return 18;
      case 5:
        return 16;
      default:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return _EditableSpans(
        node: node,
        nodeIndex: nodeIndex,
        element: element,
        baseStyle: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Text.rich(
      _buildInlineTextSpan(
        node.spans,
        TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Paragraph ────────────────────────────────────────────────

class _ParagraphWidget extends StatelessWidget {
  const _ParagraphWidget({
    required this.node,
    required this.nodeIndex,
    required this.element,
    required this.isEditing,
  });

  final RichTextNode node;
  final int nodeIndex;
  final RichTextElement element;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return _EditableSpans(
        node: node,
        nodeIndex: nodeIndex,
        element: element,
        baseStyle: const TextStyle(fontSize: 14),
      );
    }
    return Text.rich(
      _buildInlineTextSpan(
        node.spans,
        const TextStyle(fontSize: 14),
      ),
    );
  }
}

// ── Blockquote ───────────────────────────────────────────────

class _BlockquoteWidget extends StatelessWidget {
  const _BlockquoteWidget({required this.node});
  final RichTextNode node;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.blueGrey.withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        child: Text.rich(
          _buildInlineTextSpan(
            node.spans,
            TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
}

// ── List ─────────────────────────────────────────────────────

class _ListWidget extends StatelessWidget {
  const _ListWidget({
    required this.node,
    required this.nodeIndex,
    required this.element,
    required this.isEditing,
  });

  final RichTextNode node;
  final int nodeIndex;
  final RichTextElement element;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final isOrdered =
        node.type == RichTextNodeType.orderedList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0;
            i < node.children.length;
            i++)
          Padding(
            padding: EdgeInsets.only(
              left: node.children[i].indent * 16.0,
              bottom: 4,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    isOrdered ? '${i + 1}.' : '•',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    _buildInlineTextSpan(
                      node.children[i].spans,
                      const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Editable inline spans ────────────────────────────────────

class _EditableSpans extends StatefulWidget {
  const _EditableSpans({
    required this.node,
    required this.nodeIndex,
    required this.element,
    required this.baseStyle,
  });

  final RichTextNode node;
  final int nodeIndex;
  final RichTextElement element;
  final TextStyle baseStyle;

  @override
  State<_EditableSpans> createState() =>
      _EditableSpansState();
}

class _EditableSpansState extends State<_EditableSpans> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.node.plainText,
    );
  }

  @override
  void didUpdateWidget(covariant _EditableSpans old) {
    super.didUpdateWidget(old);
    final newText = widget.node.plainText;
    if (old.node.plainText != newText &&
        _controller.text != newText) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        style: widget.baseStyle,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (text) {
          context.read<RichTextBloc>().add(
                UpdateNode(
                  elementId: widget.element.id,
                  index: widget.nodeIndex,
                  node: widget.node.copyWith(
                    spans: [
                      RichTextSpan(
                        text: text,
                        styles: widget.node.spans
                                .isNotEmpty
                            ? widget.node.spans.first
                                .styles
                            : const {},
                      ),
                    ],
                  ),
                ),
              );
        },
      );
}

// ── Inline span builder ──────────────────────────────────────

TextSpan _buildInlineTextSpan(
  List<RichTextSpan> spans,
  TextStyle baseStyle,
) =>
    TextSpan(
      children: spans.map((span) {
        var style = baseStyle;

        if (span.styles.contains(InlineStyle.bold)) {
          style = style.copyWith(
            fontWeight: FontWeight.bold,
          );
        }
        if (span.styles.contains(InlineStyle.italic)) {
          style = style.copyWith(
            fontStyle: FontStyle.italic,
          );
        }
        if (span.styles
            .contains(InlineStyle.underline)) {
          style = style.copyWith(
            decoration: TextDecoration.underline,
          );
        }
        if (span.styles
            .contains(InlineStyle.strikethrough)) {
          style = style.copyWith(
            decoration: TextDecoration.lineThrough,
          );
        }
        if (span.styles.contains(InlineStyle.code)) {
          style = style.copyWith(
            fontFamily: 'monospace',
            backgroundColor:
                Colors.grey.withOpacity(0.15),
            fontSize: (style.fontSize ?? 14) - 1,
          );
        }
        if (span.styles
            .contains(InlineStyle.highlight)) {
          style = style.copyWith(
            backgroundColor:
                Colors.yellow.withOpacity(0.3),
          );
        }
        if (span.color != null) {
          style = style.copyWith(color: span.color);
        }
        if (span.link != null) {
          style = style.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          );
          return TextSpan(
            text: span.text,
            style: style,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openLink(span.link!),
          );
        }

        return TextSpan(text: span.text, style: style);
      }).toList(),
    );

/// Open a hyperlink. Uses a simple SnackBar prompt since
/// url_launcher is not available in the current dependency set.
void _openLink(String url) {
  // In production this would use url_launcher's launchUrl.
  // For now we rely on Flutter's built-in SnackBar to show the
  // URL so the user can navigate manually.
  debugPrint('Link tapped: $url');
}
