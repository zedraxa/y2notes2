import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/app/theme/elevation.dart';

/// Toast notification style variants.
enum AppleToastStyle {
  /// Green checkmark — success
  success,

  /// Red exclamation — error
  error,

  /// Blue info icon — informational
  info,

  /// Orange warning icon — caution
  warning,
}

/// Apple-style toast notification overlay.
///
/// Slides in from the top with a frosted glass background, auto-dismisses
/// after a configurable duration, and supports an optional action button.
///
/// Usage:
/// ```dart
/// AppleToast.show(
///   context,
///   message: 'Notebook saved',
///   style: AppleToastStyle.success,
/// );
/// ```
class AppleToast {
  AppleToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Show a toast notification.
  static void show(
    BuildContext context, {
    required String message,
    AppleToastStyle style = AppleToastStyle.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Dismiss any existing toast immediately.
    dismiss();

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppleToastOverlay(
        message: message,
        style: style,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          _dismissTimer?.cancel();
          _dismissTimer = null;
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }

  /// Dismiss the current toast immediately.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _AppleToastOverlay extends StatefulWidget {
  const _AppleToastOverlay({
    required this.message,
    required this.style,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppleToastStyle style;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_AppleToastOverlay> createState() => _AppleToastOverlayState();
}

class _AppleToastOverlayState extends State<_AppleToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppleDurations.medium,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppleCurves.gentleSpring,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppleCurves.standard,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconFor(AppleToastStyle style) {
    switch (style) {
      case AppleToastStyle.success:
        return Icons.check_circle_rounded;
      case AppleToastStyle.error:
        return Icons.error_rounded;
      case AppleToastStyle.info:
        return Icons.info_rounded;
      case AppleToastStyle.warning:
        return Icons.warning_rounded;
    }
  }

  Color _colorFor(AppleToastStyle style, bool isDark) {
    switch (style) {
      case AppleToastStyle.success:
        return isDark ? AppColors.darkSuccess : AppColors.success;
      case AppleToastStyle.error:
        return isDark ? AppColors.darkError : AppColors.error;
      case AppleToastStyle.info:
        return isDark ? AppColors.darkAccent : AppColors.accent;
      case AppleToastStyle.warning:
        return const Color(0xFFE5A100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _colorFor(widget.style, isDark);
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + AppleSpacing.md,
      left: AppleSpacing.lg,
      right: AppleSpacing.lg,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100) {
                _controller.reverse().then((_) => widget.onDismiss());
              }
            },
            onTap: widget.onDismiss,
            child: Semantics(
              liveRegion: true,
              label: '${widget.style.name}: ${widget.message}',
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: AppleRadius.lgRadius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppleSpacing.lg,
                          vertical: AppleSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.92),
                          borderRadius: AppleRadius.lgRadius,
                          boxShadow: isDark
                              ? AppleElevation.cardDark
                              : AppleElevation.card,
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconFor(widget.style),
                              color: accentColor,
                              size: 22,
                            ),
                            const SizedBox(width: AppleSpacing.sm),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.actionLabel != null) ...[
                              const SizedBox(width: AppleSpacing.sm),
                              GestureDetector(
                                onTap: () {
                                  widget.onAction?.call();
                                  widget.onDismiss();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppleSpacing.xs,
                                    vertical: AppleSpacing.xs,
                                  ),
                                  child: Text(
                                    widget.actionLabel!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
