import '../domain/entities/rich_text_node.dart';

/// Parses a Markdown string into a list of [RichTextNode]s.
///
/// Supports:
///  • Headings (# – ######)
///  • Fenced code blocks (``` with optional language)
///  • Unordered lists (-, *, +) with nesting
///  • Ordered lists (1., 2., …) with nesting
///  • Tables (pipe-delimited with header separator)
///  • Block quotes (>)
///  • Horizontal rules (---, ***, ___)
///  • Paragraphs with inline styles (bold, italic, code,
///    strikethrough, links)
///  • Checklists (- [ ] / - [x])
class MarkdownParser {
  const MarkdownParser();

  /// Parse the full Markdown [source] into block-level nodes.
  List<RichTextNode> parse(String source) {
    final lines = source.split('\n');
    final nodes = <RichTextNode>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      // ── Blank line → skip ─────────────────────────────
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // ── Horizontal rule ───────────────────────────────
      if (_isHorizontalRule(trimmed)) {
        nodes.add(
          const RichTextNode(type: RichTextNodeType.divider),
        );
        i++;
        continue;
      }

      // ── Heading ───────────────────────────────────────
      final headingMatch =
          RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final text = headingMatch.group(2)!;
        nodes.add(RichTextNode(
          type: RichTextNodeType.heading,
          headingLevel: level,
          spans: _parseInlineSpans(text),
        ));
        i++;
        continue;
      }

      // ── Fenced code block ─────────────────────────────
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length &&
            !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing ```
        nodes.add(RichTextNode(
          type: RichTextNodeType.codeBlock,
          language: lang.isNotEmpty ? lang : null,
          codeText: codeLines.join('\n'),
        ));
        continue;
      }

      // ── Table ─────────────────────────────────────────
      if (_isTableLine(trimmed) &&
          i + 1 < lines.length &&
          _isTableSeparator(lines[i + 1].trim())) {
        final tableLines = <String>[];
        while (i < lines.length &&
            _isTableLine(lines[i].trim())) {
          if (!_isTableSeparator(lines[i].trim())) {
            tableLines.add(lines[i].trim());
          }
          i++;
        }
        final data = tableLines.map(_parseTableRow).toList();
        nodes.add(RichTextNode(
          type: RichTextNodeType.table,
          tableData: data,
        ));
        continue;
      }

      // ── Blockquote ────────────────────────────────────
      if (trimmed.startsWith('> ') || trimmed == '>') {
        final content =
            trimmed.length > 2 ? trimmed.substring(2) : '';
        nodes.add(RichTextNode(
          type: RichTextNodeType.blockquote,
          spans: _parseInlineSpans(content),
        ));
        i++;
        continue;
      }

      // ── Unordered list ────────────────────────────────
      if (_isUnorderedListItem(trimmed)) {
        final items = <RichTextNode>[];
        while (i < lines.length &&
            _isUnorderedListItem(lines[i].trimLeft())) {
          items.add(_parseListItem(lines[i]));
          i++;
        }
        nodes.add(RichTextNode(
          type: RichTextNodeType.unorderedList,
          children: items,
        ));
        continue;
      }

      // ── Ordered list ──────────────────────────────────
      if (_isOrderedListItem(trimmed)) {
        final items = <RichTextNode>[];
        while (i < lines.length &&
            _isOrderedListItem(lines[i].trimLeft())) {
          items.add(_parseListItem(lines[i]));
          i++;
        }
        nodes.add(RichTextNode(
          type: RichTextNodeType.orderedList,
          children: items,
        ));
        continue;
      }

      // ── Paragraph (default) ───────────────────────────
      final paraLines = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        final peek = lines[i].trimLeft();
        if (_isHeading(peek) ||
            peek.startsWith('```') ||
            _isHorizontalRule(peek) ||
            _isUnorderedListItem(peek) ||
            _isOrderedListItem(peek) ||
            (peek.startsWith('> ') || peek == '>') ||
            (_isTableLine(peek) &&
                i + 1 < lines.length &&
                _isTableSeparator(lines[i + 1].trim()))) {
          break;
        }
        paraLines.add(lines[i]);
        i++;
      }
      if (paraLines.isNotEmpty) {
        nodes.add(RichTextNode(
          type: RichTextNodeType.paragraph,
          spans:
              _parseInlineSpans(paraLines.join(' ')),
        ));
      }
    }

    return nodes;
  }

  // ── Inline parsing ──────────────────────────────────────────

  /// Parse inline Markdown syntax into [RichTextSpan]s.
  List<RichTextSpan> _parseInlineSpans(String text) {
    final spans = <RichTextSpan>[];
    final pattern = RegExp(
      r'(`[^`]+`)'
      r'|(\*\*\*[^*]+\*\*\*)'
      r'|(\*\*[^*]+\*\*)'
      r'|(\*[^*]+\*)'
      r'|(~~[^~]+~~)'
      r'|(\[([^\]]+)\]\(([^)]+)\))',
    );

    var lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Plain text before this match
      if (match.start > lastEnd) {
        spans.add(RichTextSpan(
          text: text.substring(lastEnd, match.start),
        ));
      }

      final full = match.group(0)!;
      if (match.group(1) != null) {
        // Inline code
        spans.add(RichTextSpan(
          text: full.substring(1, full.length - 1),
          styles: const {InlineStyle.code},
        ));
      } else if (match.group(2) != null) {
        // Bold + italic
        spans.add(RichTextSpan(
          text: full.substring(3, full.length - 3),
          styles: const {
            InlineStyle.bold,
            InlineStyle.italic,
          },
        ));
      } else if (match.group(3) != null) {
        // Bold
        spans.add(RichTextSpan(
          text: full.substring(2, full.length - 2),
          styles: const {InlineStyle.bold},
        ));
      } else if (match.group(4) != null) {
        // Italic
        spans.add(RichTextSpan(
          text: full.substring(1, full.length - 1),
          styles: const {InlineStyle.italic},
        ));
      } else if (match.group(5) != null) {
        // Strikethrough
        spans.add(RichTextSpan(
          text: full.substring(2, full.length - 2),
          styles: const {InlineStyle.strikethrough},
        ));
      } else if (match.group(6) != null) {
        // Link
        spans.add(RichTextSpan(
          text: match.group(7)!,
          link: match.group(8),
        ));
      }

      lastEnd = match.end;
    }

    // Remaining plain text
    if (lastEnd < text.length) {
      spans.add(RichTextSpan(
        text: text.substring(lastEnd),
      ));
    }

    if (spans.isEmpty) {
      spans.add(const RichTextSpan(text: ''));
    }

    return spans;
  }

  // ── Detection helpers ───────────────────────────────────────

  bool _isHeading(String s) =>
      RegExp(r'^#{1,6}\s+').hasMatch(s);

  bool _isHorizontalRule(String s) =>
      RegExp(r'^[-*_]{3,}\s*$').hasMatch(s);

  bool _isUnorderedListItem(String s) =>
      RegExp(r'^[-*+]\s').hasMatch(s);

  bool _isOrderedListItem(String s) =>
      RegExp(r'^\d+\.\s').hasMatch(s);

  bool _isTableLine(String s) =>
      s.startsWith('|') && s.endsWith('|');

  bool _isTableSeparator(String s) =>
      RegExp(r'^\|[\s:|-]+\|$').hasMatch(s);

  List<String> _parseTableRow(String line) => line
      .split('|')
      .where((cell) => cell.isNotEmpty)
      .map((cell) => cell.trim())
      .toList();

  RichTextNode _parseListItem(String line) {
    final indentSpaces =
        line.length - line.trimLeft().length;
    final indentLevel = indentSpaces ~/ 2;
    final trimmed = line.trimLeft();

    // Strip marker (-, *, +, or 1.)
    String content;
    bool? isChecked;
    if (RegExp(r'^[-*+]\s\[[ xX]\]\s').hasMatch(trimmed)) {
      // Checklist item
      isChecked = trimmed[3] != ' ';
      content = trimmed.substring(6);
    } else if (RegExp(r'^[-*+]\s').hasMatch(trimmed)) {
      content = trimmed.substring(2);
    } else {
      // Ordered list item: strip "N. "
      final idx = trimmed.indexOf('. ');
      content = idx >= 0
          ? trimmed.substring(idx + 2)
          : trimmed;
    }

    return RichTextNode(
      type: RichTextNodeType.paragraph,
      spans: _parseInlineSpans(content),
      indent: indentLevel,
      isChecked: isChecked,
    );
  }
}
