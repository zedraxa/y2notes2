import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../engine/auto_layout.dart';
import '../bloc/infinite_canvas_bloc.dart';
import '../bloc/infinite_canvas_event.dart';
import '../bloc/infinite_canvas_state.dart';

/// The main toolbar for the infinite canvas.
///
/// Provides tool selection, auto-layout dropdown, and minimap toggle.
class InfiniteCanvasToolbar extends StatelessWidget {
  const InfiniteCanvasToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfiniteCanvasBloc, InfiniteCanvasState>(
      builder: (context, state) {
        final bloc = context.read<InfiniteCanvasBloc>();

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // ── Tool buttons ─────────────────────────────────────────
                    _ToolBtn(
                      icon: Icons.arrow_selector_tool,
                      label: 'Select',
                      isActive: state.activeTool == InfiniteCanvasTool.select,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.select)),
                    ),
                    _ToolBtn(
                      icon: Icons.pan_tool,
                      label: 'Hand',
                      isActive: state.activeTool == InfiniteCanvasTool.hand,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.hand)),
                    ),
                    const _Divider(),
                    _ToolBtn(
                      icon: Icons.draw,
                      label: 'Draw',
                      isActive:
                          state.activeTool == InfiniteCanvasTool.drawRegion,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.drawRegion)),
                    ),
                    _ToolBtn(
                      icon: Icons.text_fields,
                      label: 'Text',
                      isActive: state.activeTool == InfiniteCanvasTool.textCard,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.textCard)),
                    ),
                    _ToolBtn(
                      icon: Icons.sticky_note_2,
                      label: 'Sticky',
                      isActive:
                          state.activeTool == InfiniteCanvasTool.stickyNote,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.stickyNote)),
                    ),
                    const _Divider(),
                    _ToolBtn(
                      icon: Icons.account_tree,
                      label: 'Connect',
                      isActive:
                          state.activeTool == InfiniteCanvasTool.connection,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.connection)),
                    ),
                    _ToolBtn(
                      icon: Icons.crop_square,
                      label: 'Frame',
                      isActive: state.activeTool == InfiniteCanvasTool.frame,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.frame)),
                    ),
                    _ToolBtn(
                      icon: Icons.category,
                      label: 'Shape',
                      isActive: state.activeTool == InfiniteCanvasTool.shape,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.shape)),
                    ),
                    _ToolBtn(
                      icon: Icons.image,
                      label: 'Image',
                      isActive: state.activeTool == InfiniteCanvasTool.image,
                      onTap: () =>
                          bloc.add(const SetActiveTool(InfiniteCanvasTool.image)),
                    ),
                    const _Divider(),
                    // ── Auto-layout dropdown ──────────────────────────────────
                    _AutoLayoutBtn(
                      activeLayout: state.activeLayout,
                      onLayout: (algo) => bloc.add(ApplyLayout(algorithm: algo)),
                    ),
                    // ── Minimap toggle ─────────────────────────────────────────
                    _ToolBtn(
                      icon: Icons.map,
                      label: 'Map',
                      isActive: state.isMinimapVisible,
                      onTap: () => bloc.add(const ToggleMinimap()),
                    ),
                    // ── Undo / Redo ────────────────────────────────────────────
                    const _Divider(),
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: state.canUndo
                          ? () => bloc.add(const UndoAction())
                          : null,
                      tooltip: 'Undo',
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      onPressed: state.canRedo
                          ? () => bloc.add(const RedoAction())
                          : null,
                      tooltip: 'Redo',
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: isActive
              ? BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _AutoLayoutBtn extends StatelessWidget {
  const _AutoLayoutBtn({
    required this.activeLayout,
    required this.onLayout,
  });

  final LayoutAlgorithm? activeLayout;
  final void Function(LayoutAlgorithm) onLayout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LayoutAlgorithm>(
      tooltip: 'Auto-layout',
      icon: Icon(
        Icons.auto_fix_high,
        size: 22,
        color: activeLayout != null
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      onSelected: onLayout,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: LayoutAlgorithm.radial,
          child: ListTile(
            leading: Icon(Icons.radio_button_checked),
            title: Text('Radial'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: LayoutAlgorithm.tree,
          child: ListTile(
            leading: Icon(Icons.account_tree),
            title: Text('Tree'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: LayoutAlgorithm.forceDirected,
          child: ListTile(
            leading: Icon(Icons.scatter_plot),
            title: Text('Force Directed'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: LayoutAlgorithm.grid,
          child: ListTile(
            leading: Icon(Icons.grid_on),
            title: Text('Grid'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: LayoutAlgorithm.horizontal,
          child: ListTile(
            leading: Icon(Icons.horizontal_distribute),
            title: Text('Horizontal'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: LayoutAlgorithm.vertical,
          child: ListTile(
            leading: Icon(Icons.vertical_distribute),
            title: Text('Vertical'),
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerColor,
    );
  }
}
