import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/elevation.dart';
import 'package:biscuits/app/theme/colors.dart';

/// A frosted-glass / vibrancy container — Apple-ish toolbar style.
///
/// Uses [BackdropFilter] with a blur to simulate the translucent effect
/// seen in iOS navigation bars and tool palettes.
///
/// Now enhanced with Apple design tokens for consistent spacing and radius.
class FrostedContainer extends StatelessWidget {
  const FrostedContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blurSigma = 20,
    this.opacity,
    this.border = true,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  /// Override the background opacity. If null, defaults based on theme.
  final double? opacity;

  /// Whether to draw a subtle border.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgOpacity = opacity ?? (isDark ? 0.70 : 0.80);
    final bgColor = isDark
        ? AppColors.darkSurface.withOpacity(bgOpacity)
        : AppColors.toolbarBg.withOpacity(bgOpacity);
    final borderColor = isDark
        ? AppColors.darkDivider.withOpacity(0.4)
        : AppColors.toolbarBorder.withOpacity(0.6);
    final radius = borderRadius ?? AppleRadius.lg;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: border
                ? Border.all(color: borderColor, width: 0.5)
                : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
