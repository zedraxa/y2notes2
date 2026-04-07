import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/canvas_node.dart';
import '../../engine/infinite_canvas_engine.dart';
import '../../engine/lod_renderer.dart';
import '../../engine/node_renderer.dart';
import '../bloc/infinite_canvas_bloc.dart';
import '../bloc/infinite_canvas_event.dart';
import '../bloc/infinite_canvas_state.dart';
import 'edge_widgets/edge_painter.dart';
import 'minimap.dart';
import 'node_interaction_handler.dart';
import 'node_widgets/frame_widget.dart';
import 'node_widgets/group_widget.dart';
import 'node_widgets/image_node_widget.dart';
import 'node_widgets/sticky_note_widget.dart';
import 'node_widgets/stroke_region_widget.dart';
import 'node_widgets/text_card_widget.dart';
import 'zoom_controls.dart';

/// The main drawing surface for the infinite canvas.
///
/// Handles viewport transform, renders nodes/edges, overlays the minimap
/// and zoom controls.
class InfiniteCanvasView extends StatelessWidget {
  const InfiniteCanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfiniteCanvasBloc, InfiniteCanvasState>(
      builder: (context, state) {
        // Notify the BLoC about the screen size.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.size != state.screenSize) {
            context
                .read<InfiniteCanvasBloc>()
                .add(UpdateScreenSize(box.size));
          }
        });

        final engine = InfiniteCanvasEngine(
          worldOffset: state.viewportOffset,
          zoomLevel: state.zoomLevel,
          screenSize: state.screenSize,
        );

        final Offset Function(Offset) w2s = engine.worldToScreen;
        final lod = LodRenderer.levelFor(state.zoomLevel);
        final visibleRect = engine.visibleWorldRect;

        // Filter to visible nodes.
        final visibleNodes = state.nodes.values
            .where((n) => n.worldBounds.overlaps(visibleRect))
            .toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return NodeInteractionHandler(
          child: Stack(
            children: [
              // ── Background ──────────────────────────────────────────────
              Container(color: const Color(0xFFF8F8F8)),

              // ── Edge layer (CustomPainter) ────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: EdgePainter(
                    edges: state.edges.values.toList(),
                    nodeMap: state.nodes,
                    worldToScreen: w2s,
                    zoomLevel: state.zoomLevel,
                    selectedEdgeId: state.selectedEdgeId,
                  ),
                ),
              ),

              // ── Node overview/coarse layer (CustomPainter) ────────────
              if (lod == LodLevel.overview || lod == LodLevel.coarse)
                Positioned.fill(
                  child: CustomPaint(
                    painter: NodeRenderer(
                      visibleNodes: visibleNodes,
                      selectedNodeIds: state.selectedNodeIds,
                      zoomLevel: state.zoomLevel,
                      worldToScreen: w2s,
                      worldOffset: state.viewportOffset,
                      screenSize: state.screenSize,
                    ),
                  ),
                ),

              // ── Widget-based node layer (normal/detailed) ─────────────
              if (lod != LodLevel.overview)
                for (final node in visibleNodes) _buildNodeWidget(node, w2s, state),

              // ── Selection / handles overlay ────────────────────────────
              if (lod != LodLevel.overview)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: NodeRenderer(
                        visibleNodes: visibleNodes
                            .where((n) => state.selectedNodeIds.contains(n.id))
                            .toList(),
                        selectedNodeIds: state.selectedNodeIds,
                        zoomLevel: state.zoomLevel,
                        worldToScreen: w2s,
                        worldOffset: state.viewportOffset,
                        screenSize: state.screenSize,
                      ),
                    ),
                  ),
                ),

              // ── Zoom controls ─────────────────────────────────────────
              const Positioned(
                right: 16,
                bottom: 80,
                child: ZoomControls(),
              ),

              // ── Minimap ───────────────────────────────────────────────
              if (state.isMinimapVisible)
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: Minimap(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeWidget(
    CanvasNode node,
    Offset Function(Offset) worldToScreen,
    InfiniteCanvasState state,
  ) {
    final tl = worldToScreen(node.worldBounds.topLeft);
    final w = node.worldSize.width * state.zoomLevel;
    final h = node.worldSize.height * state.zoomLevel;
    final isSelected = state.selectedNodeIds.contains(node.id);
    final scale = state.zoomLevel;

    Widget content;
    if (node is TextCardNode) {
      content = TextCardWidget(node: node, isSelected: isSelected, scale: scale);
    } else if (node is StickyNoteNode) {
      content = StickyNoteWidget(node: node, isSelected: isSelected, scale: scale);
    } else if (node is StrokeRegionNode) {
      content = StrokeRegionWidget(node: node, isSelected: isSelected, scale: scale);
    } else if (node is ImageNode) {
      content = ImageNodeWidget(node: node, isSelected: isSelected);
    } else if (node is FrameNode) {
      content = FrameWidget(node: node, isSelected: isSelected, scale: scale);
    } else if (node is GroupNode) {
      content = GroupWidget(node: node, isSelected: isSelected, scale: scale);
    } else {
      // Generic placeholder.
      content = Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
          ),
        ),
      );
    }

    // Apply rotation if needed.
    Widget positionedNode = content;
    if (node.rotation != 0) {
      positionedNode = Transform.rotate(
        angle: node.rotation,
        child: content,
      );
    }

    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: w,
      height: h,
      child: positionedNode,
    );
  }
}
