import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../bloc/infinite_canvas_bloc.dart';
import '../../bloc/infinite_canvas_event.dart';

/// Renders a [StrokeRegionNode] on the canvas.
///
/// Shows the freehand strokes region with an optional title label.
class StrokeRegionWidget extends StatelessWidget {
  const StrokeRegionWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.scale,
  });

  final StrokeRegionNode node;
  final bool isSelected;

  /// Current canvas zoom level used to scale fonts.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<InfiniteCanvasBloc>().add(SelectNode(node.id)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Region background.
          Container(
            decoration: BoxDecoration(
              color: node.backgroundColor,
              borderRadius: BorderRadius.circular(node.cornerRadius),
              border: node.showBorder
                  ? Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2.0 : 1.0,
                    )
                  : null,
            ),
          ),
          // Title label above the region.
          if (node.title != null && node.title!.isNotEmpty)
            Positioned(
              top: -20 * scale,
              left: 0,
              child: Text(
                node.title!,
                style: TextStyle(
                  fontSize: (12 * scale).clamp(8, 18),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
