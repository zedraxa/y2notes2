import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_registry.dart';

/// A radial floating tool palette that opens at the ghost-nib position when
/// the user squeezes an Apple Pencil Pro (or triggers the mapped gesture).
///
/// Tools are arranged in a circle around the squeeze point, making it fast
/// to select a tool without lifting the pen or reaching for the toolbar.
class SqueezePaletteOverlay extends StatefulWidget {
  const SqueezePaletteOverlay({
    super.key,
    required this.position,
    required this.activeToolId,
    required this.onToolSelected,
    required this.onDismiss,
  });

  /// Centre position for the palette in canvas-local coordinates.
  final Offset position;

  /// ID of the currently active tool (shown with highlight).
  final String activeToolId;

  /// Called when the user taps a tool in the palette.
  final void Function(String toolId) onToolSelected;

  /// Called when the user taps outside the palette to dismiss.
  final VoidCallback onDismiss;

  @override
  State<SqueezePaletteOverlay> createState() => _SqueezePaletteOverlayState();
}

class _SqueezePaletteOverlayState extends State<SqueezePaletteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  /// Tools shown in the radial palette — a curated quick-access set.
  late final List<DrawingTool> _tools;

  /// Radius of the ring on which tool icons are placed.
  static const double _ringRadius = 72.0;

  /// Size of each tool button.
  static const double _buttonSize = 44.0;

  /// Total diameter of the palette hit area.
  static const double _paletteSize = (_ringRadius + _buttonSize) * 2;

  /// Duration of the open/close animation in milliseconds.
  static const int _animDurationMs = 220;

  @override
  void initState() {
    super.initState();
    _tools = _buildQuickAccessTools();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _animDurationMs),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the curated list of quick-access tools for the radial palette.
  ///
  /// Picks at most 8 representative tools across categories so the ring
  /// doesn't get overcrowded.
  List<DrawingTool> _buildQuickAccessTools() {
    // Preferred tool IDs for the quick-access ring.
    const preferred = [
      'fountain_pen',
      'ballpoint',
      'pencil_hb',
      'watercolor',
      'classic_highlighter',
      'felt_tip',
      'brush_pen',
      'eraser',
    ];
    final result = <DrawingTool>[];
    for (final id in preferred) {
      final tool = ToolRegistry.get(id);
      if (tool != null) result.add(tool);
    }
    // Fall back to first 8 registered tools if preferred set is empty.
    if (result.isEmpty) {
      result.addAll(ToolRegistry.getAll().take(8));
    }
    return result;
  }

  void _selectTool(String toolId) {
    widget.onToolSelected(toolId);
    // The onToolSelected callback closes the palette via bloc state;
    // the widget will be removed from the tree, which disposes the controller.
  }

  void _animateOut() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toolCount = _tools.length;

    return Positioned(
      left: widget.position.dx - _paletteSize / 2,
      top: widget.position.dy - _paletteSize / 2,
      width: _paletteSize,
      height: _paletteSize,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            // Absorb taps inside the palette area to prevent them from
            // falling through to the canvas drawing layer.
            onTap: () {}, // swallow taps on dead space inside the palette
            child: Stack(
              children: [
                // ── Frosted backdrop circle ──────────────────────────────────
                Center(
                  child: Container(
                    width: _ringRadius * 2 + _buttonSize,
                    height: _ringRadius * 2 + _buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF2C2420).withOpacity(0.85)
                          : const Color(0xFFFFFBF6).withOpacity(0.92),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4A3F38).withOpacity(0.5)
                            : const Color(0xFFEDE3D8).withOpacity(0.7),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Centre dot (nib marker) ─────────────────────────────────
                Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFFA89888).withOpacity(0.6)
                          : const Color(0xFF8C7B6B).withOpacity(0.4),
                    ),
                  ),
                ),
                // ── Tool buttons arranged in a ring ─────────────────────────
                for (int i = 0; i < toolCount; i++)
                  _buildToolButton(context, i, toolCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, int index, int total) {
    final tool = _tools[index];
    final isActive = tool.id == widget.activeToolId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Distribute tools evenly around the ring, starting from the top.
    final angle = (2 * math.pi * index / total) - (math.pi / 2);
    final dx = _paletteSize / 2 + _ringRadius * math.cos(angle) - _buttonSize / 2;
    final dy = _paletteSize / 2 + _ringRadius * math.sin(angle) - _buttonSize / 2;

    final activeColor = isDark
        ? const Color(0xFFDEB887)
        : const Color(0xFFD4A574);
    final inactiveColor = isDark
        ? const Color(0xFFF5E6D3)
        : const Color(0xFF3D2B1F);

    return Positioned(
      left: dx,
      top: dy,
      child: _AnimatedToolButton(
        delay: Duration(milliseconds: 30 * index),
        parentAnimation: _scaleAnimation,
        child: GestureDetector(
          onTap: () => _selectTool(tool.id),
          child: Tooltip(
            message: tool.name,
            waitDuration: const Duration(milliseconds: 400),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: _buttonSize,
              height: _buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? activeColor.withOpacity(0.25)
                    : (isDark
                        ? const Color(0xFF3A302A)
                        : const Color(0xFFFFFFFF)),
                border: Border.all(
                  color: isActive
                      ? activeColor
                      : (isDark
                          ? const Color(0xFF4A3F38).withOpacity(0.6)
                          : const Color(0xFFEDE3D8)),
                  width: isActive ? 2.0 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  tool.icon,
                  size: 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Applies a staggered scale-in animation to each tool button for a
/// polished radial reveal effect.
class _AnimatedToolButton extends StatelessWidget {
  const _AnimatedToolButton({
    required this.delay,
    required this.parentAnimation,
    required this.child,
  });

  final Duration delay;
  final Animation<double> parentAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: parentAnimation,
      builder: (_, __) {
        // Each button pops in slightly after the previous one.
        final delayFraction =
            (delay.inMilliseconds /
                    _SqueezePaletteOverlayState._animDurationMs)
                .clamp(0.0, 0.8);
        final progress = ((parentAnimation.value - delayFraction) /
                (1.0 - delayFraction))
            .clamp(0.0, 1.0);
        return Transform.scale(
          scale: Curves.easeOutBack.transform(progress),
          child: Opacity(
            opacity: progress,
            child: child,
          ),
        );
      },
    );
  }
}
