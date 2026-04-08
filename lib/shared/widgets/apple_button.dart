import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/elevation.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Apple-style button with smooth press animations and haptic feedback.
///
/// Features:
/// - Scales down on press with spring animation
/// - Smooth color transitions for all states
/// - Proper elevation and shadows
/// - Follows 44pt minimum touch target
class AppleButton extends StatefulWidget {
  const AppleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = AppleButtonVariant.filled,
    this.size = AppleButtonSize.medium,
    this.fullWidth = false,
    this.enabled = true,
    this.icon,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AppleButtonVariant variant;
  final AppleButtonSize size;
  final bool fullWidth;
  final bool enabled;
  final IconData? icon;

  /// When true, displays a loading spinner and disables interaction.
  final bool isLoading;

  @override
  State<AppleButton> createState() => _AppleButtonState();
}

class _AppleButtonState extends State<AppleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppleDurations.quick,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppleCurves.gentleSpring,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.enabled && widget.onPressed != null && !widget.isLoading;

    // Size configuration
    final double height;
    final EdgeInsets padding;
    final double fontSize;
    switch (widget.size) {
      case AppleButtonSize.small:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
        fontSize = 13;
        break;
      case AppleButtonSize.medium:
        height = 44;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        fontSize = 15;
        break;
      case AppleButtonSize.large:
        height = 52;
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 14);
        fontSize = 17;
        break;
    }

    // Color configuration based on variant
    final Color backgroundColor;
    final Color foregroundColor;
    final Color? borderColor;
    final List<BoxShadow>? shadows;

    switch (widget.variant) {
      case AppleButtonVariant.filled:
        backgroundColor = isEnabled
            ? (isDark ? AppColors.darkAccent : AppColors.accent)
            : (isDark ? AppColors.darkDivider : AppColors.toolbarBorder);
        foregroundColor = isEnabled
            ? (isDark ? AppColors.darkBackground : Colors.white)
            : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary);
        borderColor = null;
        shadows = isEnabled
            ? (isDark ? AppleElevation.cardDark : AppleElevation.card)
            : null;
        break;
      case AppleButtonVariant.tinted:
        backgroundColor = isEnabled
            ? (isDark
                ? AppColors.darkAccent.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.15))
            : (isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant);
        foregroundColor = isEnabled
            ? (isDark ? AppColors.darkAccent : AppColors.accent)
            : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary);
        borderColor = null;
        shadows = null;
        break;
      case AppleButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? (isDark ? AppColors.darkAccent : AppColors.accent)
            : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary);
        borderColor = foregroundColor;
        shadows = null;
        break;
      case AppleButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
            : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary);
        borderColor = null;
        shadows = null;
        break;
    }

    final buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: fontSize + 2),
          const SizedBox(width: 8),
        ],
        DefaultTextStyle(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: foregroundColor,
          ),
          child: widget.child,
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: isEnabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: AppleDurations.quick,
            curve: AppleCurves.standard,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppleRadius.pillRadius,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
              boxShadow: shadows,
            ),
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}

enum AppleButtonVariant {
  /// Filled with accent color (primary action)
  filled,

  /// Tinted background with accent color text
  tinted,

  /// Transparent with border
  outlined,

  /// Transparent without border (text only)
  ghost,
}

enum AppleButtonSize {
  small,
  medium,
  large,
}

/// Apple-style icon button with press feedback.
class AppleIconButton extends StatefulWidget {
  const AppleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 22,
    this.enabled = true,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool enabled;
  final String? badge;

  @override
  State<AppleIconButton> createState() => _AppleIconButtonState();
}

class _AppleIconButtonState extends State<AppleIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppleDurations.quick,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppleCurves.gentleSpring,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;
    final color = isEnabled
        ? Theme.of(context).iconTheme.color
        : Theme.of(context).disabledColor;

    Widget iconWidget = ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: color,
      ),
    );

    // Add badge if provided
    if (widget.badge != null) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  widget.badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: iconWidget,
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
