import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../bloc/infinite_canvas_bloc.dart';
import '../../bloc/infinite_canvas_event.dart';

/// Renders a [TextCardNode] with inline editing support.
class TextCardWidget extends StatefulWidget {
  const TextCardWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.scale,
  });

  final TextCardNode node;
  final bool isSelected;
  final double scale;

  @override
  State<TextCardWidget> createState() => _TextCardWidgetState();
}

class _TextCardWidgetState extends State<TextCardWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.text);
  }

  @override
  void didUpdateWidget(TextCardWidget old) {
    super.didUpdateWidget(old);
    if (old.node.text != widget.node.text && !_editing) {
      _ctrl.text = widget.node.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commitEdit() {
    setState(() => _editing = false);
    context.read<InfiniteCanvasBloc>().add(
          UpdateNode(widget.node.copyWith(text: _ctrl.text)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<InfiniteCanvasBloc>().add(SelectNode(widget.node.id)),
      onDoubleTap: () => setState(() => _editing = true),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.node.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected ? Colors.blue : Colors.grey.shade300,
            width: widget.isSelected ? 2.0 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _editing
            ? TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: null,
                onSubmitted: (_) => _commitEdit(),
                onTapOutside: (_) => _commitEdit(),
                style: TextStyle(
                  fontSize: (widget.node.fontSize * widget.scale).clamp(8, 48),
                  color: widget.node.textColor,
                ),
                decoration: const InputDecoration.collapsed(hintText: ''),
                textAlign: widget.node.alignment,
              )
            : Text(
                widget.node.text,
                textAlign: widget.node.alignment,
                style: TextStyle(
                  fontSize: (widget.node.fontSize * widget.scale).clamp(8, 48),
                  color: widget.node.textColor,
                ),
              ),
      ),
    );
  }
}
