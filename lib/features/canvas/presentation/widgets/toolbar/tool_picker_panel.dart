import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';

/// A categorized panel that lets the user pick any registered DrawingTool.
class ToolPickerPanel extends StatefulWidget {
  const ToolPickerPanel({super.key, this.onToolSelected});

  final void Function(String toolId)? onToolSelected;

  @override
  State<ToolPickerPanel> createState() => _ToolPickerPanelState();
}

class _ToolPickerPanelState extends State<ToolPickerPanel> {
  ToolCategory _selectedCategory = ToolCategory.ink;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      builder: (context, state) {
        final tools = ToolRegistry.getByCategory(_selectedCategory);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CategoryTabBar(
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 200,
              child: tools.isEmpty
                  ? const Center(child: Text('No tools available'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: tools.length,
                      itemBuilder: (context, index) {
                        final tool = tools[index];
                        final isActive = tool.id == state.activeToolId;
                        return _ToolTile(
                          tool: tool,
                          isActive: isActive,
                          onTap: () {
                            context.read<CanvasBloc>().add(DrawingToolChanged(tool.id));
                            widget.onToolSelected?.call(tool.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({required this.selected, required this.onSelected});

  final ToolCategory selected;
  final void Function(ToolCategory) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: ToolCategory.values.map((cat) {
          final isSelected = cat == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(_categoryLabel(cat)),
              selected: isSelected,
              onSelected: (_) => onSelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _categoryLabel(ToolCategory cat) => switch (cat) {
    ToolCategory.ink => 'Ink',
    ToolCategory.paint => 'Paint',
    ToolCategory.dry => 'Dry',
    ToolCategory.glow => 'Glow',
    ToolCategory.highlighter => 'Highlight',
    ToolCategory.utility => 'Utility',
    ToolCategory.shape => 'Shape',
  };
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.tool,
    required this.isActive,
    required this.onTap,
  });

  final DrawingTool tool;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tool.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            border: isActive
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Center(
            child: Icon(
              tool.icon,
              size: 22,
              color: isActive ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
