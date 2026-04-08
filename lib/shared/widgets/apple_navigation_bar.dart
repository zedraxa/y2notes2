import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/elevation.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Apple-style navigation bar with frosted glass effect and large titles.
///
/// Features:
/// - Translucent background with blur
/// - Large title that shrinks on scroll (like iOS)
/// - Smooth animations
/// - Proper safe area handling
class AppleNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const AppleNavigationBar({
    super.key,
    this.title,
    this.largeTitle,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.useLargeTitle = false,
  });

  final Widget? title;
  final String? largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool useLargeTitle;

  @override
  Size get preferredSize => Size.fromHeight(
        (useLargeTitle ? 96.0 : 56.0) + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.toolbarBg);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: (isDark
                        ? AppColors.darkDivider
                        : AppColors.toolbarBorder)
                    .withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  child: NavigationToolbar(
                    leading: leading,
                    middle: !useLargeTitle && title != null
                        ? DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            child: title!,
                          )
                        : null,
                    trailing: actions != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          )
                        : null,
                  ),
                ),
                if (useLargeTitle && largeTitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppleSpacing.lg,
                      AppleSpacing.xs,
                      AppleSpacing.lg,
                      AppleSpacing.md,
                    ),
                    child: Text(
                      largeTitle!,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsible navigation bar that transitions between large and normal titles.
class AppleScrollableNavigationBar extends StatefulWidget {
  const AppleScrollableNavigationBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.scrollController,
    this.backgroundColor,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final ScrollController? scrollController;
  final Color? backgroundColor;

  @override
  State<AppleScrollableNavigationBar> createState() =>
      _AppleScrollableNavigationBarState();
}

class _AppleScrollableNavigationBarState
    extends State<AppleScrollableNavigationBar> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.toolbarBg);

    // Calculate collapse progress (0.0 = fully expanded, 1.0 = fully collapsed)
    final collapseProgress = (_scrollOffset / 60.0).clamp(0.0, 1.0);
    final largeTitleOpacity = 1.0 - collapseProgress;
    final smallTitleOpacity = collapseProgress;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: AppleDurations.quick,
          curve: AppleCurves.standard,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.85 + (0.1 * collapseProgress)),
            border: Border(
              bottom: BorderSide(
                color: (isDark
                        ? AppColors.darkDivider
                        : AppColors.toolbarBorder)
                    .withOpacity(0.3 * collapseProgress),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  child: NavigationToolbar(
                    leading: widget.leading,
                    middle: Opacity(
                      opacity: smallTitleOpacity,
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    trailing: widget.actions != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.actions!,
                          )
                        : null,
                  ),
                ),
                AnimatedContainer(
                  duration: AppleDurations.quick,
                  curve: AppleCurves.standard,
                  height: 40 * largeTitleOpacity,
                  child: Opacity(
                    opacity: largeTitleOpacity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppleSpacing.lg,
                        AppleSpacing.xs,
                        AppleSpacing.lg,
                        AppleSpacing.md,
                      ),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button with Apple-style chevron.
class AppleBackButton extends StatelessWidget {
  const AppleBackButton({
    super.key,
    this.onPressed,
    this.label,
  });

  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextButton.icon(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        Icons.chevron_left_rounded,
        size: 28,
        color: isDark ? AppColors.darkAccent : AppColors.accent,
      ),
      label: Text(
        label ?? 'Back',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.darkAccent : AppColors.accent,
          letterSpacing: -0.2,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(left: 4, right: 12),
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
