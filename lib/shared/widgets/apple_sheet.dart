import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/elevation.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Shows an Apple-style bottom sheet with blur and vibrancy.
///
/// Features:
/// - Frosted glass background
/// - Smooth slide-up animation
/// - Drag to dismiss
/// - Proper safe area handling
Future<T?> showAppleBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: true,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: AppleDurations.medium,
    ),
    builder: (context) => AppleBottomSheetContainer(
      backgroundColor: backgroundColor,
      elevation: elevation,
      child: builder(context),
    ),
  );
}

/// Container for Apple-style bottom sheets with frosted glass effect.
class AppleBottomSheetContainer extends StatelessWidget {
  const AppleBottomSheetContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.elevation,
    this.showHandle = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final double? elevation;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppleRadius.bottomSheetRadius,
        boxShadow: isDark
            ? AppleElevation.bottomSheetDark
            : AppleElevation.bottomSheet,
      ),
      child: ClipRRect(
        borderRadius: AppleRadius.bottomSheetRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.95),
              borderRadius: AppleRadius.bottomSheetRadius,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHandle) const _BottomSheetHandle(),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppleSpacing.sm),
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkDivider : AppColors.toolbarBorder)
            .withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppleRadius.xs),
      ),
    );
  }
}

/// Shows an Apple-style alert dialog.
///
/// Features:
/// - Blur background
/// - Smooth fade-scale animation
/// - Proper button styling
/// - iOS-like layout
Future<T?> showAppleDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  List<AppleDialogAction>? actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppleDurations.medium,
    pageBuilder: (context, animation, secondaryAnimation) =>
        AppleAlertDialog(
      title: title,
      content: content,
      contentWidget: contentWidget,
      actions: actions ?? [],
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: AppleCurves.gentleSpring,
        ),
      );

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Apple-style alert dialog widget.
class AppleAlertDialog extends StatelessWidget {
  const AppleAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.actions = const [],
  });

  final String title;
  final String? content;
  final Widget? contentWidget;
  final List<AppleDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppleSpacing.xxxl),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          borderRadius: AppleRadius.xlRadius,
          boxShadow:
              isDark ? AppleElevation.dialogDark : AppleElevation.dialog,
        ),
        child: ClipRRect(
          borderRadius: AppleRadius.xlRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurface : AppColors.surface)
                    .withOpacity(0.95),
                borderRadius: AppleRadius.xlRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppleSpacing.xxl,
                      AppleSpacing.xxl,
                      AppleSpacing.xxl,
                      AppleSpacing.md,
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (content != null || contentWidget != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppleSpacing.xxl,
                        0,
                        AppleSpacing.xxl,
                        AppleSpacing.xxl,
                      ),
                      child: contentWidget ??
                          Text(
                            content!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                    ),
                  if (actions.isNotEmpty) _buildActions(context, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    if (actions.length == 1) {
      return Column(
        children: [
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
          ),
          _ActionButton(action: actions[0]),
        ],
      );
    }

    if (actions.length == 2) {
      return Column(
        children: [
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
          ),
          Row(
            children: [
              Expanded(child: _ActionButton(action: actions[0])),
              Container(
                width: 0.5,
                height: 44,
                color:
                    isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
              ),
              Expanded(child: _ActionButton(action: actions[1])),
            ],
          ),
        ],
      );
    }

    // More than 2 actions: stack vertically
    return Column(
      children: [
        for (final action in actions) ...[
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
          ),
          _ActionButton(action: action),
        ],
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.action});

  final AppleDialogAction action;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = widget.action.isDestructive
        ? AppColors.error
        : (widget.action.isDefault
            ? (isDark ? AppColors.darkAccent : AppColors.accent)
            : (isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        widget.action.onPressed?.call();
        Navigator.of(context).pop(widget.action.result);
      },
      child: AnimatedContainer(
        duration: AppleDurations.quick,
        curve: AppleCurves.standard,
        height: 44,
        color: _isPressed
            ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
            : Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          widget.action.label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: widget.action.isDefault
                ? FontWeight.w600
                : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Action button configuration for Apple dialogs.
class AppleDialogAction {
  const AppleDialogAction({
    required this.label,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
    this.result,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
  final dynamic result;
}

/// Shows an Apple-style action sheet.
///
/// Similar to iOS UIActionSheet with blur and proper styling.
Future<T?> showAppleActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppleActionSheetAction<T>> actions,
  AppleActionSheetAction<T>? cancelAction,
}) {
  return showAppleBottomSheet<T>(
    context: context,
    builder: (context) => AppleActionSheet<T>(
      title: title,
      message: message,
      actions: actions,
      cancelAction: cancelAction,
    ),
  );
}

/// Apple-style action sheet widget.
class AppleActionSheet<T> extends StatelessWidget {
  const AppleActionSheet({
    super.key,
    this.title,
    this.message,
    required this.actions,
    this.cancelAction,
  });

  final String? title;
  final String? message;
  final List<AppleActionSheetAction<T>> actions;
  final AppleActionSheetAction<T>? cancelAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || message != null)
          Padding(
            padding: const EdgeInsets.all(AppleSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (message != null) ...[
                  const SizedBox(height: AppleSpacing.xs),
                  Text(
                    message!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        for (final action in actions) ...[
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
          ),
          _ActionSheetButton<T>(action: action),
        ],
        if (cancelAction != null) ...[
          const SizedBox(height: AppleSpacing.sm),
          _ActionSheetButton<T>(
            action: cancelAction!,
            isCancel: true,
          ),
        ],
        const SizedBox(height: AppleSpacing.sm),
      ],
    );
  }
}

class _ActionSheetButton<T> extends StatefulWidget {
  const _ActionSheetButton({
    required this.action,
    this.isCancel = false,
  });

  final AppleActionSheetAction<T> action;
  final bool isCancel;

  @override
  State<_ActionSheetButton<T>> createState() => _ActionSheetButtonState<T>();
}

class _ActionSheetButtonState<T> extends State<_ActionSheetButton<T>> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = widget.action.isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkAccent : AppColors.accent);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // Pop the action sheet first, then invoke the callback in a
        // post-frame callback so that any dialog / route pushed by
        // the action is not immediately popped by the sheet dismissal.
        final callback = widget.action.onPressed;
        Navigator.of(context).pop(widget.action.result);
        if (callback != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callback();
          });
        }
      },
      child: AnimatedContainer(
        duration: AppleDurations.quick,
        curve: AppleCurves.standard,
        height: 56,
        color: _isPressed
            ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
            : Colors.transparent,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.action.icon != null) ...[
              Icon(
                widget.action.icon,
                size: 22,
                color: textColor,
              ),
              const SizedBox(width: AppleSpacing.sm),
            ],
            Text(
              widget.action.label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: widget.isCancel
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action configuration for Apple action sheets.
class AppleActionSheetAction<T> {
  const AppleActionSheetAction({
    required this.label,
    this.onPressed,
    this.isDestructive = false,
    this.icon,
    this.result,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final IconData? icon;
  final T? result;
}
