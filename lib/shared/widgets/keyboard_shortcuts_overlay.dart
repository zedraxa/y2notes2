import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/app/theme/elevation.dart';

/// Full-screen keyboard shortcuts help overlay.
///
/// Shows all available keyboard shortcuts grouped by category.
/// Triggered by pressing ⌘+/ (or Ctrl+/) anywhere in the app.
///
/// Usage:
/// ```dart
/// KeyboardShortcutsOverlay.show(context);
/// ```
class KeyboardShortcutsOverlay extends StatefulWidget {
  const KeyboardShortcutsOverlay({super.key});

  /// Show the keyboard shortcuts overlay.
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss shortcuts',
      barrierColor: Colors.black45,
      transitionDuration: AppleDurations.medium,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const KeyboardShortcutsOverlay(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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

  @override
  State<KeyboardShortcutsOverlay> createState() =>
      _KeyboardShortcutsOverlayState();
}

class _KeyboardShortcutsOverlayState extends State<KeyboardShortcutsOverlay> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final keyBgColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppleSpacing.xxl),
          child: ClipRRect(
            borderRadius: AppleRadius.xlRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: bgColor.withOpacity(0.95),
                borderRadius: AppleRadius.xlRadius,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppleSpacing.xxl,
                        AppleSpacing.xl,
                        AppleSpacing.lg,
                        AppleSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.keyboard_rounded,
                            color: isDark
                                ? AppColors.darkAccent
                                : AppColors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: AppleSpacing.sm),
                          Expanded(
                            child: Text(
                              'Keyboard Shortcuts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppleRadius.pill,
                              ),
                              onTap: () => Navigator.of(context).pop(),
                              child: Padding(
                                padding: const EdgeInsets.all(AppleSpacing.sm),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.toolbarBorder,
                    ),
                    // Shortcuts list
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppleSpacing.md,
                        ),
                        shrinkWrap: true,
                        children: [
                          _ShortcutSection(
                            title: 'General',
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            keyBgColor: keyBgColor,
                            shortcuts: const [
                              _ShortcutEntry('⌘ K', 'Spotlight Search'),
                              _ShortcutEntry('⌘ /', 'Show Shortcuts'),
                              _ShortcutEntry('⌘ ,', 'Open Settings'),
                            ],
                          ),
                          _ShortcutSection(
                            title: 'Workspace',
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            keyBgColor: keyBgColor,
                            shortcuts: const [
                              _ShortcutEntry('⌘ T', 'New Tab'),
                              _ShortcutEntry('⌘ W', 'Close Tab'),
                              _ShortcutEntry('⌘ Tab', 'Next Tab'),
                              _ShortcutEntry('⌘ Shift Tab', 'Previous Tab'),
                            ],
                          ),
                          _ShortcutSection(
                            title: 'Canvas',
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            keyBgColor: keyBgColor,
                            shortcuts: const [
                              _ShortcutEntry('⌘ Z', 'Undo'),
                              _ShortcutEntry('⌘ Shift Z', 'Redo'),
                              _ShortcutEntry('⌘ N', 'New Notebook'),
                              _ShortcutEntry('⌘ E', 'Export'),
                            ],
                          ),
                          _ShortcutSection(
                            title: 'Drawing Tools',
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            keyBgColor: keyBgColor,
                            shortcuts: const [
                              _ShortcutEntry('P', 'Pen Tool'),
                              _ShortcutEntry('H', 'Highlighter'),
                              _ShortcutEntry('E', 'Eraser'),
                              _ShortcutEntry('S', 'Shape Tool'),
                              _ShortcutEntry('T', 'Text Tool'),
                              _ShortcutEntry('[', 'Decrease Thickness'),
                              _ShortcutEntry(']', 'Increase Thickness'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Footer hint
                    Padding(
                      padding: const EdgeInsets.all(AppleSpacing.md),
                      child: Text(
                        'Press Esc or ⌘/ to close',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection({
    required this.title,
    required this.shortcuts,
    required this.textColor,
    required this.secondaryColor,
    required this.keyBgColor,
  });

  final String title;
  final List<_ShortcutEntry> shortcuts;
  final Color textColor;
  final Color secondaryColor;
  final Color keyBgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppleSpacing.xxl,
            AppleSpacing.md,
            AppleSpacing.xxl,
            AppleSpacing.xs,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...shortcuts.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppleSpacing.xxl,
              vertical: AppleSpacing.xs + 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ),
                _KeyCap(label: s.keys, bgColor: keyBgColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortcutEntry {
  const _ShortcutEntry(this.keys, this.description);
  final String keys;
  final String description;
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label, required this.bgColor});

  final String label;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    // Split multi-key combos into individual caps.
    final parts = label.split(' ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '+',
                style: TextStyle(fontSize: 10, color: textColor),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? AppColors.darkDivider
                    : AppColors.toolbarBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              parts[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
