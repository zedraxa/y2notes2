import 'package:flutter/material.dart';

import '../../domain/entities/rich_text_node.dart';

/// Renders a code block with syntax highlighting and a language
/// label.
class CodeBlockWidget extends StatelessWidget {
  const CodeBlockWidget({
    required this.node,
    required this.onChanged,
    this.isEditing = false,
    super.key,
  });

  final RichTextNode node;
  final ValueChanged<String> onChanged;
  final bool isEditing;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language label
            if (node.language != null &&
                node.language!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  6,
                  12,
                  0,
                ),
                child: Text(
                  node.language!,
                  style: const TextStyle(
                    color: Color(0xFF858585),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            // Code content
            Padding(
              padding: const EdgeInsets.all(12),
              child: isEditing
                  ? _EditableCode(
                      text: node.codeText ?? '',
                      onChanged: onChanged,
                    )
                  : _ReadOnlyCode(
                      text: node.codeText ?? '',
                      language: node.language,
                    ),
            ),
          ],
        ),
      );
}

class _ReadOnlyCode extends StatelessWidget {
  const _ReadOnlyCode({
    required this.text,
    this.language,
  });

  final String text;
  final String? language;

  @override
  Widget build(BuildContext context) =>
      SelectableText.rich(
        _buildHighlightedSpan(text, language),
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontSize: 13,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      );
}

class _EditableCode extends StatefulWidget {
  const _EditableCode({
    required this.text,
    required this.onChanged,
  });

  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<_EditableCode> createState() =>
      _EditableCodeState();
}

class _EditableCodeState extends State<_EditableCode> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant _EditableCode old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text &&
        _controller.text != widget.text) {
      _controller.text = widget.text;
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
        maxLines: null,
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontSize: 13,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      );
}

// ── Multi-language syntax highlighting ───────────────────────

/// Language keyword sets for syntax highlighting.
const _languageKeywords = <String, List<String>>{
  'dart': [
    'abstract', 'as', 'assert', 'async', 'await',
    'break', 'case', 'catch', 'class', 'const',
    'continue', 'default', 'deferred', 'do', 'dynamic',
    'else', 'enum', 'export', 'extends', 'factory',
    'false', 'final', 'finally', 'for', 'Function',
    'get', 'if', 'implements', 'import', 'in',
    'interface', 'is', 'late', 'library', 'mixin',
    'new', 'null', 'on', 'operator', 'part',
    'required', 'rethrow', 'return', 'set', 'show',
    'static', 'super', 'switch', 'sync', 'this',
    'throw', 'true', 'try', 'typedef', 'var', 'void',
    'while', 'with', 'yield',
  ],
  'python': [
    'False', 'None', 'True', 'and', 'as', 'assert',
    'async', 'await', 'break', 'class', 'continue',
    'def', 'del', 'elif', 'else', 'except', 'finally',
    'for', 'from', 'global', 'if', 'import', 'in',
    'is', 'lambda', 'nonlocal', 'not', 'or', 'pass',
    'raise', 'return', 'try', 'while', 'with', 'yield',
  ],
  'javascript': [
    'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'debugger',
    'default', 'delete', 'do', 'else', 'export',
    'extends', 'false', 'finally', 'for', 'from',
    'function', 'if', 'import', 'in', 'instanceof',
    'let', 'new', 'null', 'of', 'return', 'static',
    'super', 'switch', 'this', 'throw', 'true', 'try',
    'typeof', 'undefined', 'var', 'void', 'while',
    'with', 'yield',
  ],
  'typescript': [
    'abstract', 'any', 'as', 'async', 'await',
    'boolean', 'break', 'case', 'catch', 'class',
    'const', 'continue', 'debugger', 'declare',
    'default', 'delete', 'do', 'else', 'enum',
    'export', 'extends', 'false', 'finally', 'for',
    'from', 'function', 'if', 'implements', 'import',
    'in', 'instanceof', 'interface', 'keyof', 'let',
    'module', 'namespace', 'never', 'new', 'null',
    'number', 'object', 'of', 'private', 'protected',
    'public', 'readonly', 'return', 'static', 'string',
    'super', 'switch', 'symbol', 'this', 'throw',
    'true', 'try', 'type', 'typeof', 'undefined',
    'unknown', 'var', 'void', 'while', 'with', 'yield',
  ],
  'html': [
    'DOCTYPE', 'html', 'head', 'body', 'div', 'span',
    'p', 'a', 'img', 'ul', 'ol', 'li', 'table', 'tr',
    'td', 'th', 'form', 'input', 'button', 'script',
    'style', 'link', 'meta', 'title', 'section',
    'header', 'footer', 'nav', 'main', 'article',
  ],
  'css': [
    'color', 'background', 'border', 'margin',
    'padding', 'font', 'display', 'position', 'width',
    'height', 'top', 'left', 'right', 'bottom', 'flex',
    'grid', 'align', 'justify', 'overflow', 'opacity',
    'transform', 'transition', 'animation', 'none',
    'auto', 'inherit', 'initial', 'important',
  ],
  'sql': [
    'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO',
    'UPDATE', 'DELETE', 'CREATE', 'ALTER', 'DROP',
    'TABLE', 'INDEX', 'VIEW', 'JOIN', 'INNER', 'LEFT',
    'RIGHT', 'OUTER', 'ON', 'AND', 'OR', 'NOT', 'IN',
    'IS', 'NULL', 'AS', 'ORDER', 'BY', 'GROUP',
    'HAVING', 'LIMIT', 'OFFSET', 'UNION', 'ALL',
    'DISTINCT', 'SET', 'VALUES', 'DEFAULT', 'PRIMARY',
    'KEY', 'FOREIGN', 'REFERENCES', 'CASCADE',
    'CONSTRAINT', 'EXISTS', 'BETWEEN', 'LIKE', 'COUNT',
    'SUM', 'AVG', 'MAX', 'MIN',
  ],
  'go': [
    'break', 'case', 'chan', 'const', 'continue',
    'default', 'defer', 'else', 'fallthrough', 'for',
    'func', 'go', 'goto', 'if', 'import', 'interface',
    'map', 'package', 'range', 'return', 'select',
    'struct', 'switch', 'type', 'var', 'true', 'false',
    'nil',
  ],
  'rust': [
    'as', 'async', 'await', 'break', 'const',
    'continue', 'crate', 'dyn', 'else', 'enum',
    'extern', 'false', 'fn', 'for', 'if', 'impl',
    'in', 'let', 'loop', 'match', 'mod', 'move',
    'mut', 'pub', 'ref', 'return', 'self', 'Self',
    'static', 'struct', 'super', 'trait', 'true',
    'type', 'unsafe', 'use', 'where', 'while',
  ],
};

/// Aliases that map to a canonical language name.
const _languageAliases = <String, String>{
  'js': 'javascript',
  'ts': 'typescript',
  'py': 'python',
  'htm': 'html',
  'golang': 'go',
  'rs': 'rust',
};

/// Build a highlighted [TextSpan] for the given [code] and
/// optional [language].
TextSpan _buildHighlightedSpan(
  String code, [
  String? language,
]) {
  final lang = language?.toLowerCase().trim();
  final resolvedLang = lang != null
      ? (_languageAliases[lang] ?? lang)
      : null;

  // Look up keywords for the language, fall back to Dart
  final words = _languageKeywords[resolvedLang] ??
      _languageKeywords['dart']!;

  final escaped =
      words.map(RegExp.escape).join('|');
  final keywords = RegExp('\\b($escaped)\\b');

  // String pattern (single and double quotes)
  final strings =
      RegExp(r'''("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')''');

  // Single-line comment pattern
  final comments = RegExp(r'(//.*?$|#.*?$)', multiLine: true);

  // Number pattern
  final numbers = RegExp(r'\b(\d+\.?\d*)\b');

  // Build a combined pattern to tokenise in one pass.
  // Group layout:
  //   group(1) = comment
  //   group(2) = string
  //   group(3) = keyword
  //   group(4) = number
  final combined = RegExp(
    '(?<comment>${comments.pattern})'
    '|(?<string>${strings.pattern})'
    '|(?<keyword>${keywords.pattern})'
    '|(?<number>${numbers.pattern})',
    multiLine: true,
  );

  final spans = <TextSpan>[];
  var lastEnd = 0;

  for (final match in combined.allMatches(code)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: code.substring(lastEnd, match.start),
      ));
    }

    final text = match.group(0)!;
    TextStyle style;

    if (match.namedGroup('comment') != null) {
      style = const TextStyle(
        color: Color(0xFF6A9955),
        fontStyle: FontStyle.italic,
      );
    } else if (match.namedGroup('string') != null) {
      style = const TextStyle(
        color: Color(0xFFCE9178),
      );
    } else if (match.namedGroup('keyword') != null) {
      style = const TextStyle(
        color: Color(0xFF569CD6),
        fontWeight: FontWeight.bold,
      );
    } else {
      style = const TextStyle(
        color: Color(0xFFB5CEA8),
      );
    }

    spans.add(TextSpan(text: text, style: style));
    lastEnd = match.end;
  }

  if (lastEnd < code.length) {
    spans.add(TextSpan(
      text: code.substring(lastEnd),
    ));
  }

  return TextSpan(children: spans);
}
