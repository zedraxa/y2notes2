import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/features/canvas/domain/entities/tool.dart';

/// Displays pen-type selection buttons (fountain pen, ballpoint, highlighter,
/// eraser) with an active indicator and smooth animated transitions.
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: 44,
        height: AppConstants.toolbarHeight,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withOpacity(0.06)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              duration: const Duration(milliseconds: 150),
              builder: (_, color, __) => Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 2),
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              duration: const Duration(milliseconds: 150),
              builder: (_, color, __) => Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
