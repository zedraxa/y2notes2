import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Star/sparkle icon toggle for all writing effects with smooth transitions.
class EffectsToggle extends StatelessWidget {
  const EffectsToggle({
    super.key,
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: enabled ? 'Effects On' : 'Effects Off',
        child: GestureDetector(
          onTap: () => onToggle(!enabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.accent.withOpacity(0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: enabled
                  ? Border.all(
                      color: AppColors.accent.withOpacity(0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: enabled ? AppColors.accent : AppColors.textSecondary,
              ),
              duration: const Duration(milliseconds: 200),
              builder: (context, color, _) => Icon(
                enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                size: 22,
                color: color,
              ),
            ),
          ),
        ),
      );
}
