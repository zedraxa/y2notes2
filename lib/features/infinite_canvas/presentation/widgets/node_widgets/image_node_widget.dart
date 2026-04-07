import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/canvas_node.dart';
import '../../bloc/infinite_canvas_bloc.dart';
import '../../bloc/infinite_canvas_event.dart';

/// Renders an [ImageNode] on the canvas.
class ImageNodeWidget extends StatelessWidget {
  const ImageNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
  });

  final ImageNode node;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<InfiniteCanvasBloc>().add(SelectNode(node.id)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Opacity(
          opacity: node.opacity,
          child: Image(
            image: _resolveImage(node.imagePath),
            fit: node.fit,
          ),
        ),
      ),
    );
  }

  ImageProvider _resolveImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }
}
