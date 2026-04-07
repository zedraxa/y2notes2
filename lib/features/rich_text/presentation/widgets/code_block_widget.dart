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
                    ),
            ),
          ],
        ),
      );
}

class _ReadOnlyCode extends StatelessWidget {
  const _ReadOnlyCode({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) =>
      SelectableText.rich(
        _buildHighlightedSpan(text),
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

// ── Minimal syntax highlighting ──────────────────────────────

/// Simple keyword-based highlighting suitable for previewing
/// code on the canvas.
TextSpan _buildHighlightedSpan(String code) {
  final keywords = RegExp(
    r'\b(abstract|as|assert|async|await|break|case|catch|'
    r'class|const|continue|default|deferred|do|dynamic|'
    r'else|enum|export|extends|factory|false|final|'
    r'finally|for|Function|get|if|implements|import|in|'
    r'interface|is|late|library|mixin|new|null|on|'
    r'operator|part|required|rethrow|return|set|show|'
    r'static|super|switch|sync|this|throw|true|try|'
    r'typedef|var|void|while|with|yield)\b',
  );

  final spans = <TextSpan>[];
  var lastEnd = 0;

  for (final match in keywords.allMatches(code)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: code.substring(lastEnd, match.start),
      ));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: const TextStyle(
        color: Color(0xFF569CD6),
        fontWeight: FontWeight.bold,
      ),
    ));
    lastEnd = match.end;
  }

  if (lastEnd < code.length) {
    spans.add(TextSpan(
      text: code.substring(lastEnd),
    ));
  }

  return TextSpan(children: spans);
}
