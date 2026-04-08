import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Compact slider for stroke thickness with a smoothly animated preview dot.
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
  Widget build(BuildContext context) {
    final dotSize = value.clamp(3.0, 20.0);
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          // Animated preview dot – smoothly transitions size and shadow.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: dotSize * 0.3,
                      ),
                    ],
                  ),
                ),
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
}
