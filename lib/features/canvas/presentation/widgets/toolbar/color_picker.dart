import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/constants/app_constants.dart';

/// Row of 8 preset colour swatches + a tap-for-custom-colour button.
class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.activeColor,
    required this.onColorSelected,
  });

  final Color activeColor;
  final void Function(Color) onColorSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppConstants.toolbarHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Preset swatches
            ...AppColors.defaultPenColors.map(
              (c) => _ColorSwatch(
                color: c,
                isSelected: activeColor.value == c.value,
                onTap: () => onColorSelected(c),
              ),
            ),
            const SizedBox(width: 4),
            // Custom colour picker
            _CustomColorButton(
              current: activeColor,
              onColorSelected: onColorSelected,
            ),
          ],
        ),
      );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppConstants.colorSwatchSize,
          height: AppConstants.colorSwatchSize,
          margin: EdgeInsets.symmetric(
            horizontal: AppConstants.colorSwatchSpacing / 2,
          ),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: Colors.white,
                    width: 2.5,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      );
}

class _CustomColorButton extends StatelessWidget {
  const _CustomColorButton({
    required this.current,
    required this.onColorSelected,
  });

  final Color current;
  final void Function(Color) onColorSelected;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _showColorDialog(context),
        child: Container(
          width: AppConstants.colorSwatchSize,
          height: AppConstants.colorSwatchSize,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Colors.red,
                Colors.yellow,
                Colors.green,
                Colors.cyan,
                Colors.blue,
                Colors.purple,
                Colors.red,
              ],
            ),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Icon(Icons.add, size: 12, color: Colors.white),
        ),
      );

  Future<void> _showColorDialog(BuildContext context) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorDialog(initial: current),
    );
    if (picked != null) onColorSelected(picked);
  }
}

/// Simple colour selection dialog offering an extended palette.
class _ColorDialog extends StatefulWidget {
  const _ColorDialog({required this.initial});

  final Color initial;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late Color _selected;

  static const _palette = [
    ...AppColors.defaultPenColors,
    Colors.white,
    Color(0xFFBDBDBD),
    Color(0xFF795548),
    Color(0xFF009688),
    Color(0xFF8BC34A),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF03A9F4),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFF4CAF50),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFFF44336),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Choose Colour'),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette
                .map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _selected = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selected.value == c.value
                            ? Border.all(
                                color: AppColors.accent,
                                width: 3,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )
                            : null,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Select'),
          ),
        ],
      );
}
