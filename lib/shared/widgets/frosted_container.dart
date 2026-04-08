import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted-glass / vibrancy container — Apple-ish toolbar style.
///
/// Uses [BackdropFilter] with a blur to simulate the translucent effect
/// seen in iOS navigation bars and tool palettes.
class FrostedContainer extends StatelessWidget {
  const FrostedContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.blurSigma = 20,
    this.opacity,
    this.border = true,
  });

  final Widget child;
  final double borderRadius;
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
        ? const Color(0xFF2C2420).withOpacity(bgOpacity)
        : const Color(0xFFFFFBF6).withOpacity(bgOpacity);
    final borderColor = isDark
        ? const Color(0xFF4A3F38).withOpacity(0.4)
        : const Color(0xFFEDE3D8).withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
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
