import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// The type of a rich text node.
enum RichTextNodeType {
  /// A paragraph of inline content.
  paragraph,

  /// Heading levels 1–6.
  heading,

  /// A fenced or indented code block with optional language tag.
  codeBlock,

  /// An unordered (bulleted) list.
  unorderedList,

  /// An ordered (numbered) list.
  orderedList,

  /// A table with rows and columns.
  table,

  /// A block-level quote.
  blockquote,

  /// A horizontal divider / thematic break.
  divider,
}

/// Inline formatting styles that may be combined on a text span.
enum InlineStyle {
  bold,
  italic,
  underline,
  strikethrough,
  code,
  highlight,
}

/// A single inline span within a rich text node.
///
/// Spans carry text content together with a set of [InlineStyle]s and
/// an optional text colour override.
class RichTextSpan extends Equatable {
  const RichTextSpan({
    required this.text,
    this.styles = const {},
    this.color,
    this.link,
  });

  /// The raw text content.
  final String text;

  /// Set of active inline styles.
  final Set<InlineStyle> styles;

  /// Optional colour override for this span.
  final Color? color;

  /// Optional hyperlink URL.
  final String? link;

  RichTextSpan copyWith({
    String? text,
    Set<InlineStyle>? styles,
    Color? color,
    bool clearColor = false,
    String? link,
    bool clearLink = false,
  }) =>
      RichTextSpan(
        text: text ?? this.text,
        styles: styles ?? this.styles,
        color: clearColor ? null : (color ?? this.color),
        link: clearLink ? null : (link ?? this.link),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'styles': styles.map((s) => s.name).toList(),
        if (color != null) 'color': color!.value,
        if (link != null) 'link': link,
      };

  factory RichTextSpan.fromJson(Map<String, dynamic> json) =>
      RichTextSpan(
        text: json['text'] as String,
        styles: (json['styles'] as List<dynamic>? ?? [])
            .map((s) => InlineStyle.values.byName(s as String))
            .toSet(),
        color: json['color'] != null
            ? Color(json['color'] as int)
            : null,
        link: json['link'] as String?,
      );

  @override
  List<Object?> get props => [text, styles, color, link];
}

/// A single block-level node in a rich text document.
///
/// Each node represents one structural element such as a paragraph,
/// heading, code block, list, or table.
class RichTextNode extends Equatable {
  const RichTextNode({
    required this.type,
    this.spans = const [],
    this.headingLevel = 1,
    this.language,
    this.codeText,
    this.indent = 0,
    this.children = const [],
    this.tableData,
    this.isChecked,
  });

  /// The structural type of this node.
  final RichTextNodeType type;

  /// Inline spans (used by paragraph, heading, blockquote, list
  /// items).
  final List<RichTextSpan> spans;

  /// Heading level 1–6 (only meaningful when [type] is
  /// [RichTextNodeType.heading]).
  final int headingLevel;

  /// Programming language hint for syntax highlighting (only
  /// meaningful when [type] is [RichTextNodeType.codeBlock]).
  final String? language;

  /// Raw source text of a code block.
  final String? codeText;

  /// Nesting depth for list items (0 = top level).
  final int indent;

  /// Nested children — used for list items (each child is a
  /// paragraph or sub-list) and table cells.
  final List<RichTextNode> children;

  /// Row-major table data: outer list = rows, inner list = cell
  /// strings.
  final List<List<String>>? tableData;

  /// Whether a checklist item is ticked. `null` means this is not
  /// a checklist item.
  final bool? isChecked;

  /// Plain-text content extracted from all [spans].
  String get plainText =>
      spans.map((s) => s.text).join();

  RichTextNode copyWith({
    RichTextNodeType? type,
    List<RichTextSpan>? spans,
    int? headingLevel,
    String? language,
    bool clearLanguage = false,
    String? codeText,
    bool clearCodeText = false,
    int? indent,
    List<RichTextNode>? children,
    List<List<String>>? tableData,
    bool clearTableData = false,
    bool? isChecked,
    bool clearIsChecked = false,
  }) =>
      RichTextNode(
        type: type ?? this.type,
        spans: spans ?? this.spans,
        headingLevel: headingLevel ?? this.headingLevel,
        language: clearLanguage
            ? null
            : (language ?? this.language),
        codeText: clearCodeText
            ? null
            : (codeText ?? this.codeText),
        indent: indent ?? this.indent,
        children: children ?? this.children,
        tableData: clearTableData
            ? null
            : (tableData ?? this.tableData),
        isChecked: clearIsChecked
            ? null
            : (isChecked ?? this.isChecked),
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'spans': spans.map((s) => s.toJson()).toList(),
        if (type == RichTextNodeType.heading)
          'headingLevel': headingLevel,
        if (language != null) 'language': language,
        if (codeText != null) 'codeText': codeText,
        if (indent > 0) 'indent': indent,
        if (children.isNotEmpty)
          'children':
              children.map((c) => c.toJson()).toList(),
        if (tableData != null) 'tableData': tableData,
        if (isChecked != null) 'isChecked': isChecked,
      };

  factory RichTextNode.fromJson(Map<String, dynamic> json) =>
      RichTextNode(
        type: RichTextNodeType.values
            .byName(json['type'] as String),
        spans: (json['spans'] as List<dynamic>? ?? [])
            .map(
              (s) => RichTextSpan.fromJson(
                s as Map<String, dynamic>,
              ),
            )
            .toList(),
        headingLevel:
            (json['headingLevel'] as int?) ?? 1,
        language: json['language'] as String?,
        codeText: json['codeText'] as String?,
        indent: (json['indent'] as int?) ?? 0,
        children:
            (json['children'] as List<dynamic>? ?? [])
                .map(
                  (c) => RichTextNode.fromJson(
                    c as Map<String, dynamic>,
                  ),
                )
                .toList(),
        tableData: (json['tableData'] as List<dynamic>?)
            ?.map(
              (row) => (row as List<dynamic>)
                  .map((cell) => cell as String)
                  .toList(),
            )
            .toList(),
        isChecked: json['isChecked'] as bool?,
      );

  @override
  List<Object?> get props => [
        type,
        spans,
        headingLevel,
        language,
        codeText,
        indent,
        children,
        tableData,
        isChecked,
      ];
}
