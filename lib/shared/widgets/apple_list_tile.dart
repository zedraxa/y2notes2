import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/elevation.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Apple-style card with subtle elevation and smooth interactions.
///
/// Features:
/// - Soft shadows matching iOS design
/// - Smooth press animations
/// - Proper corner radius and spacing
/// - Support for inset grouped list style
class AppleCard extends StatefulWidget {
  const AppleCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation = AppleElevation.level2,
    this.showChevron = false,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final bool showChevron;
  final Color? backgroundColor;

  @override
  State<AppleCard> createState() => _AppleCardState();
}

class _AppleCardState extends State<AppleCard>
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
      end: 0.98,
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
    if (widget.onTap == null) return;
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
    final bgColor = widget.backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);

    Widget cardContent = Container(
      padding: widget.padding ?? AppleSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppleRadius.lgRadius,
        border: Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.toolbarBorder)
              .withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: isDark
            ? AppleElevation.shadowFor(widget.elevation, isDark: true)
            : AppleElevation.shadowFor(widget.elevation),
      ),
      child: Row(
        children: [
          Expanded(child: widget.child),
          if (widget.showChevron)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppleSpacing.lg,
            vertical: AppleSpacing.sm,
          ),
      child: cardContent,
    );
  }
}

/// Apple-style list tile matching iOS Settings design.
///
/// Features:
/// - Inset grouped list appearance
/// - Leading/trailing widgets
/// - Subtitle support
/// - Smooth press animation
/// - Automatic chevron for navigation
class AppleListTile extends StatefulWidget {
  const AppleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.backgroundColor,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? showChevron;
  final Color? backgroundColor;

  @override
  State<AppleListTile> createState() => _AppleListTileState();
}

class _AppleListTileState extends State<AppleListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppleDurations.quick,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalColor = widget.backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final pressedColor = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;

    _colorAnimation = ColorTween(
      begin: normalColor,
      end: pressedColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppleCurves.standard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
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
    final showChevron = widget.showChevron ?? (widget.onTap != null);

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) => GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Container(
          color: _colorAnimation.value,
          padding: const EdgeInsets.symmetric(
            horizontal: AppleSpacing.lg,
            vertical: AppleSpacing.md,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: AppleSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      child: widget.title,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        child: widget.subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: AppleSpacing.md),
                widget.trailing!,
              ],
              if (showChevron) ...[
                const SizedBox(width: AppleSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inset grouped list container (iOS Settings style).
///
/// Groups multiple list items with rounded corners and proper spacing.
class AppleInsetGroup extends StatelessWidget {
  const AppleInsetGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin,
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppleSpacing.lg,
            vertical: AppleSpacing.md,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppleSpacing.sm,
                bottom: AppleSpacing.xs,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
                child: header!,
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: AppleRadius.lgRadius,
              border: Border.all(
                color: (isDark
                        ? AppColors.darkDivider
                        : AppColors.toolbarBorder)
                    .withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: AppleSpacing.lg),
                      child: Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.toolbarBorder,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppleSpacing.sm,
                top: AppleSpacing.xs,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                child: footer!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
