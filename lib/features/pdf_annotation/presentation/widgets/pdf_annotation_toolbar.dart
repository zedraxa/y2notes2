import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';

/// Toolbar for PDF annotation tools.
///
/// Displays tool buttons (text select, highlight, underline,
/// strikethrough, sticky note, form fill) and a colour picker.
class PdfAnnotationToolbar extends StatelessWidget {
  const PdfAnnotationToolbar({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PdfAnnotationBloc, PdfAnnotationState>(
        builder: (context, state) {
          final bloc = context.read<PdfAnnotationBloc>();
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.text_fields_rounded,
                  label: 'Select',
                  isActive:
                      state.activeTool == PdfAnnotationTool.textSelect,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.textSelect,
                  )),
                ),
                _ToolButton(
                  icon: Icons.highlight_rounded,
                  label: 'Highlight',
                  isActive:
                      state.activeTool == PdfAnnotationTool.highlight,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.highlight,
                  )),
                ),
                _ToolButton(
                  icon: Icons.format_underlined_rounded,
                  label: 'Underline',
                  isActive:
                      state.activeTool == PdfAnnotationTool.underline,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.underline,
                  )),
                ),
                _ToolButton(
                  icon: Icons.format_strikethrough_rounded,
                  label: 'Strike',
                  isActive: state.activeTool ==
                      PdfAnnotationTool.strikethrough,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.strikethrough,
                  )),
                ),
                _ToolButton(
                  icon: Icons.sticky_note_2_rounded,
                  label: 'Note',
                  isActive:
                      state.activeTool == PdfAnnotationTool.stickyNote,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.stickyNote,
                  )),
                ),
                _ToolButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Form',
                  isActive:
                      state.activeTool == PdfAnnotationTool.formFill,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.formFill,
                  )),
                ),
                const Spacer(),
                // Colour picker row.
                ..._colorOptions.map(
                  (color) => _ColorDot(
                    color: color,
                    isSelected: state.activeColor == color,
                    onTap: () => bloc.add(
                      SetAnnotationColor(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Deselect tool.
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Deselect tool',
                  iconSize: 20,
                  onPressed: () => bloc.add(const SetAnnotationTool(
                    tool: PdfAnnotationTool.none,
                  )),
                ),
              ],
            ),
          );
        },
      );

  static const _colorOptions = [
    Color(0x80FFEB3B), // Yellow
    Color(0x804CAF50), // Green
    Color(0x802196F3), // Blue
    Color(0x80F44336), // Red
    Color(0x80E91E63), // Pink
    Color(0x80FF9800), // Orange
  ];
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: Material(
        color: isActive
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  semanticLabel: label,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color:
                          Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
          ),
        ),
      );
}
