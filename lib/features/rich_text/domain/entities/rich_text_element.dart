import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'rich_text_node.dart';

/// A rich text block placed on the canvas.
///
/// Follows the same entity pattern as [ShapeElement] and
/// [StickerElement]: position, size, rotation, opacity, UUID, and
/// full JSON serialisation.
class RichTextElement extends Equatable {
  RichTextElement({
    String? id,
    required this.position,
    this.width = 400.0,
    this.height,
    this.nodes = const [],
    this.backgroundColor = Colors.transparent,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.isEditing = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;

  /// Top-left position on the canvas.
  final Offset position;

  /// Layout width constraint. Height is determined by content
  /// unless explicitly set.
  final double width;

  /// Explicit height override (null = auto-size to content).
  final double? height;

  /// Ordered list of block-level nodes that form the document.
  final List<RichTextNode> nodes;

  /// Background fill behind the text block.
  final Color backgroundColor;

  final double opacity;

  /// Rotation in radians around the element centre.
  final double rotation;

  /// Whether the user is currently editing this element.
  final bool isEditing;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Bounding rectangle on the canvas.
  Rect get bounds => Rect.fromLTWH(
        position.dx,
        position.dy,
        width,
        height ?? 200.0,
      );

  /// Concatenated plain text of all nodes.
  String get plainText =>
      nodes.map((n) => n.plainText).join('\n');

  /// Converts the element back into a Markdown string.
  String get markdown =>
      nodes.map(_nodeToMarkdown).join('\n\n');

  RichTextElement copyWith({
    Offset? position,
    double? width,
    double? height,
    bool clearHeight = false,
    List<RichTextNode>? nodes,
    Color? backgroundColor,
    double? opacity,
    double? rotation,
    bool? isEditing,
    DateTime? updatedAt,
  }) =>
      RichTextElement(
        id: id,
        position: position ?? this.position,
        width: width ?? this.width,
        height: clearHeight
            ? null
            : (height ?? this.height),
        nodes: nodes ?? this.nodes,
        backgroundColor:
            backgroundColor ?? this.backgroundColor,
        opacity: opacity ?? this.opacity,
        rotation: rotation ?? this.rotation,
        isEditing: isEditing ?? this.isEditing,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  // ── Serialisation ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': position.dx,
        'y': position.dy,
        'width': width,
        if (height != null) 'height': height,
        'nodes':
            nodes.map((n) => n.toJson()).toList(),
        'backgroundColor': backgroundColor.value,
        'opacity': opacity,
        'rotation': rotation,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RichTextElement.fromJson(
    Map<String, dynamic> json,
  ) =>
      RichTextElement(
        id: json['id'] as String,
        position: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
        width: (json['width'] as num).toDouble(),
        height: json['height'] != null
            ? (json['height'] as num).toDouble()
            : null,
        nodes: (json['nodes'] as List<dynamic>)
            .map(
              (n) => RichTextNode.fromJson(
                n as Map<String, dynamic>,
              ),
            )
            .toList(),
        backgroundColor:
            Color(json['backgroundColor'] as int),
        opacity:
            (json['opacity'] as num).toDouble(),
        rotation:
            (json['rotation'] as num).toDouble(),
        createdAt: DateTime.parse(
          json['createdAt'] as String,
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] as String,
        ),
      );

  // ── Markdown generation helpers ────────────────────────────

  static String _nodeToMarkdown(RichTextNode node) {
    switch (node.type) {
      case RichTextNodeType.heading:
        final prefix = '#' * node.headingLevel;
        return '$prefix ${_spansToMarkdown(node.spans)}';
      case RichTextNodeType.codeBlock:
        final lang = node.language ?? '';
        return '```$lang\n${node.codeText ?? ''}\n```';
      case RichTextNodeType.unorderedList:
        return node.children
            .map(
              (c) =>
                  '${'  ' * c.indent}- '
                  '${_spansToMarkdown(c.spans)}',
            )
            .join('\n');
      case RichTextNodeType.orderedList:
        final buf = StringBuffer();
        for (var i = 0; i < node.children.length; i++) {
          final c = node.children[i];
          buf.write(
            '${'  ' * c.indent}${i + 1}. '
            '${_spansToMarkdown(c.spans)}',
          );
          if (i < node.children.length - 1) buf.write('\n');
        }
        return buf.toString();
      case RichTextNodeType.table:
        if (node.tableData == null ||
            node.tableData!.isEmpty) {
          return '';
        }
        return _tableToMarkdown(node.tableData!);
      case RichTextNodeType.blockquote:
        return '> ${_spansToMarkdown(node.spans)}';
      case RichTextNodeType.divider:
        return '---';
      case RichTextNodeType.paragraph:
        return _spansToMarkdown(node.spans);
    }
  }

  static String _spansToMarkdown(
    List<RichTextSpan> spans,
  ) =>
      spans.map(_spanToMarkdown).join();

  static String _spanToMarkdown(RichTextSpan span) {
    var text = span.text;
    if (span.styles.contains(InlineStyle.code)) {
      text = '`$text`';
    }
    if (span.styles.contains(InlineStyle.bold)) {
      text = '**$text**';
    }
    if (span.styles.contains(InlineStyle.italic)) {
      text = '*$text*';
    }
    if (span.styles.contains(InlineStyle.strikethrough)) {
      text = '~~$text~~';
    }
    if (span.link != null) {
      text = '[$text](${span.link})';
    }
    return text;
  }

  static String _tableToMarkdown(
    List<List<String>> data,
  ) {
    if (data.isEmpty) return '';
    final header = '| ${data.first.join(' | ')} |';
    final sep = '| ${data.first.map((_) => '---').join(' | ')} |';
    final rows = data
        .skip(1)
        .map((row) => '| ${row.join(' | ')} |');
    return [header, sep, ...rows].join('\n');
  }

  @override
  List<Object?> get props => [
        id,
        position,
        width,
        height,
        nodes,
        backgroundColor,
        opacity,
        rotation,
        isEditing,
        createdAt,
        updatedAt,
      ];
}
