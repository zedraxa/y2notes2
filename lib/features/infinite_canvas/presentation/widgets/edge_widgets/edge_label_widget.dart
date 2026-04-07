import 'package:flutter/material.dart';

/// Renders a text label along an edge.
///
/// Positioned in world space and transformed to screen space by the parent
/// [InfiniteCanvasView].
class EdgeLabelWidget extends StatelessWidget {
  const EdgeLabelWidget({
    super.key,
    required this.label,
    required this.screenPosition,
    this.color = const Color(0xFF757575),
  });

  final String label;

  /// The screen-space position of the edge midpoint.
  final Offset screenPosition;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenPosition.dx,
      top: screenPosition.dy,
      child: Transform.translate(
        offset: const Offset(-50, -12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
