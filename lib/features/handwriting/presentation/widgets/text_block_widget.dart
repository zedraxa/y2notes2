import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/handwriting/domain/entities/text_block.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_event.dart';

/// Renders a [TextBlock] on the canvas with interaction (tap to edit, drag).
class TextBlockWidget extends StatefulWidget {
  const TextBlockWidget({
    super.key,
    required this.block,
    this.onTap,
    this.onLongPress,
  });

  final TextBlock block;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late Offset _position;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.block.position;
  }

  @override
  void didUpdateWidget(covariant TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.position != widget.block.position) {
      _position = widget.block.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress ?? () => _showContextMenu(context),
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          context.read<HandwritingBloc>().add(
                TextBlockMoved(id: widget.block.id, newPosition: _position),
              );
        },
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Transform.rotate(
      angle: widget.block.rotation,
      child: AnimatedOpacity(
        opacity: widget.block.opacity,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.block.width,
          constraints: const BoxConstraints(minHeight: 24),
          decoration: BoxDecoration(
            color: widget.block.backgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: _isDragging
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  )
                : null,
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            widget.block.text,
            style: widget.block.style,
            textAlign: widget.block.align,
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final bloc = context.read<HandwritingBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _TextBlockContextMenu(
        block: widget.block,
        onCopy: () {
          Navigator.pop(ctx);
          Clipboard.setData(ClipboardData(text: widget.block.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text copied to clipboard')),
          );
        },
        onDelete: () {
          Navigator.pop(ctx);
          bloc.add(TextBlockDeleted(widget.block.id));
        },
        onRevert: () {
          Navigator.pop(ctx);
          bloc.add(RevertToHandwriting(widget.block.id));
        },
      ),
    );
  }
}

class _TextBlockContextMenu extends StatelessWidget {
  const _TextBlockContextMenu({
    required this.block,
    required this.onCopy,
    required this.onDelete,
    required this.onRevert,
  });

  final TextBlock block;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '"${block.text.length > 40 ? '${block.text.substring(0, 40)}…' : block.text}"',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Copy text'),
            onTap: onCopy,
          ),
          ListTile(
            leading: const Icon(Icons.undo_outlined),
            title: const Text('Revert to handwriting'),
            onTap: onRevert,
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
