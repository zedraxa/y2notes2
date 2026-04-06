import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';

/// Star/sparkle icon toggle for all writing effects.
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.accent.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              size: 22,
              color: enabled ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      );
}
