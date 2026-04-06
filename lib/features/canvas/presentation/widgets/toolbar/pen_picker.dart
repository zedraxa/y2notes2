import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';

/// Displays pen-type selection buttons (fountain pen, ballpoint, highlighter,
/// eraser) with an active indicator.
class PenPicker extends StatelessWidget {
  const PenPicker({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
  });

  final Tool activeTool;
  final void Function(Tool tool) onToolSelected;

  static const _tools = [
    Tool.defaultFountainPen,
    Tool.defaultBallpoint,
    Tool.defaultHighlighter,
    Tool.defaultEraser,
  ];

  static const _icons = [
    Icons.create_outlined,       // fountain pen
    Icons.edit_outlined,         // ballpoint
    Icons.format_color_fill_outlined, // highlighter
    Icons.auto_fix_normal_outlined,  // eraser
  ];

  static const _labels = ['Pen', 'Ball', 'Hi', 'Erase'];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _tools.length,
          (i) => _ToolButton(
            icon: _icons[i],
            label: _labels[i],
            isActive: activeTool.type == _tools[i].type,
            onTap: () => onToolSelected(_tools[i].copyWith(
              color: activeTool.color,
              baseWidth: activeTool.baseWidth,
            )),
          ),
        ),
      );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
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
    final color = isActive ? AppColors.accent : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: AppConstants.toolbarHeight,
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppColors.accent, width: 2),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 8, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
