import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../bloc/infinite_canvas_bloc.dart';
import '../../bloc/infinite_canvas_event.dart';

/// Renders a [StickyNoteNode] with editable text.
class StickyNoteWidget extends StatefulWidget {
  const StickyNoteWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.scale,
  });

  final StickyNoteNode node;
  final bool isSelected;
  final double scale;

  @override
  State<StickyNoteWidget> createState() => _StickyNoteWidgetState();
}

class _StickyNoteWidgetState extends State<StickyNoteWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.text);
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.node.color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isSelected
                ? Colors.blue
                : widget.node.color.withOpacity(0.6),
            width: widget.isSelected ? 2.0 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 4),
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
                  color: Colors.black87,
                ),
                decoration: const InputDecoration.collapsed(hintText: ''),
              )
            : Text(
                widget.node.text,
                style: TextStyle(
                  fontSize: (widget.node.fontSize * widget.scale).clamp(8, 48),
                  color: Colors.black87,
                ),
              ),
      ),
    );
  }
}
