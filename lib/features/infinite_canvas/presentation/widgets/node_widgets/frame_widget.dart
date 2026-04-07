import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../bloc/infinite_canvas_bloc.dart';
import '../../bloc/infinite_canvas_event.dart';

/// Renders a [FrameNode] — a labelled container region.
class FrameWidget extends StatelessWidget {
  const FrameWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.scale,
  });

  final FrameNode node;
  final bool isSelected;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<InfiniteCanvasBloc>().add(SelectNode(node.id)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            clipBehavior:
                node.clipContent ? Clip.hardEdge : Clip.none,
            decoration: BoxDecoration(
              color: node.frameColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Colors.blue : node.frameColor,
                width: isSelected ? 2.0 : 1.5,
              ),
            ),
          ),
          // Label tab above the frame.
          Positioned(
            top: -(20 * scale),
            left: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale, vertical: 2 * scale),
              decoration: BoxDecoration(
                color: node.frameColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(4 * scale)),
              ),
              child: Text(
                node.label,
                style: TextStyle(
                  fontSize: (11 * scale).clamp(8, 16),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
