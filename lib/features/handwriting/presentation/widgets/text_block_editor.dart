import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/handwriting/domain/entities/text_block.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_event.dart';

/// Inline editor for a [TextBlock]. Shown when user taps a text block.
class TextBlockEditor extends StatefulWidget {
  const TextBlockEditor({
    super.key,
    required this.block,
    required this.onDone,
  });

  final TextBlock block;
  final VoidCallback onDone;

  @override
  State<TextBlockEditor> createState() => _TextBlockEditorState();
}

class _TextBlockEditorState extends State<TextBlockEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    context.read<HandwritingBloc>().add(
          TextBlockEdited(
            id: widget.block.id,
            newText: _controller.text,
          ),
        );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toolbar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Text',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: widget.onDone,
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => _save(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: null,
              autofocus: true,
              style: widget.block.style,
              textAlign: widget.block.align,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _save(context),
            ),
          ],
        ),
      ),
    );
  }
}
