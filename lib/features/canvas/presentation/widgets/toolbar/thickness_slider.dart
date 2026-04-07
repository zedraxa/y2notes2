import 'package:flutter/material.dart';
import 'package:biscuitse/app/theme/colors.dart';

/// Compact slider for stroke thickness with a live preview dot.
class ThicknessSlider extends StatelessWidget {
  const ThicknessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.color,
    this.min = 0.5,
    this.max = 40.0,
  });

  final double value;
  final void Function(double) onChanged;
  final Color color;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 130,
        child: Row(
          children: [
            // Preview dot
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: value.clamp(3.0, 20.0),
                height: value.clamp(3.0, 20.0),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.toolbarBorder,
                thumbColor: color,
              ),
            ),
          ],
        ),
      );
}
