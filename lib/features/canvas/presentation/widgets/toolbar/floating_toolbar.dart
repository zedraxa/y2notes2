import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/core/engine/haptic_controller.dart';
import 'package:biscuits/features/canvas/domain/entities/tool.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/tool_picker_panel.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/tool_settings_panel.dart';
import 'package:biscuits/features/collaboration/presentation/widgets/share_button.dart';
import 'package:biscuits/features/documents/presentation/pages/notebook_page_view.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_state.dart';
import 'package:biscuits/features/math_graph/presentation/bloc/graph_bloc.dart';
import 'package:biscuits/features/math_graph/presentation/bloc/graph_event.dart';
import 'package:biscuits/features/media/presentation/bloc/media_bloc.dart';
import 'package:biscuits/features/media/presentation/bloc/media_event.dart';
import 'package:biscuits/features/media/presentation/widgets/media_picker_panel.dart';
import 'package:biscuits/features/rich_text/presentation/bloc/rich_text_bloc.dart';
import 'package:biscuits/features/rich_text/presentation/bloc/rich_text_event.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_type.dart';
import 'package:biscuits/features/shapes/presentation/widgets/shape_type_picker.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_event.dart';
import 'package:biscuits/features/stickers/presentation/widgets/sticker_picker_panel.dart';
import 'package:biscuits/features/templates/domain/entities/page_template.dart';
import 'package:biscuits/features/templates/presentation/bloc/template_bloc.dart';
import 'package:biscuits/features/templates/presentation/bloc/template_event.dart';
import 'package:biscuits/features/templates/presentation/widgets/template_picker.dart';
import 'package:biscuits/features/widgets/presentation/bloc/widget_bloc.dart';
import 'package:biscuits/features/widgets/presentation/bloc/widget_event.dart';
import 'package:biscuits/features/widgets/presentation/widgets/widget_picker_panel.dart';

/// Which expandable section of the toolbar tray is open.
enum _ExpandedSection { none, tools, insert }

/// A floating, draggable toolbar overlay for the canvas.
///
/// Features:
/// - Frosted glass backdrop with rounded pill shape
/// - Draggable to any position on screen
/// - Collapses to a minimal handle when tapped
/// - Auto-hides during active drawing
/// - Primary tools always visible; secondary tools in an expandable tray
class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({
    super.key,
    this.onSettingsTap,
  });

  final VoidCallback? onSettingsTap;

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar>
    with SingleTickerProviderStateMixin {
  /// Position offset from top-center default.
  Offset _position = Offset.zero;

  /// Whether the toolbar is in its collapsed (minimal) form.
  bool _collapsed = false;

  /// Which expandable section is currently visible.
  _ExpandedSection _expandedSection = _ExpandedSection.none;

  /// Controls the slide/fade animation when hiding during drawing.
  late final AnimationController _hideController;
  late final Animation<double> _hideAnimation;

  /// Tracks whether the user is currently drawing so we can auto-hide.
  bool _wasDrawing = false;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hideAnimation = CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Start fully visible.
    _hideController.value = 1.0;
  }

  @override
  void dispose() {
    _hideController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _toggleCollapse() {
    HapticController.light();
    setState(() {
      _collapsed = !_collapsed;
      if (_collapsed) _expandedSection = _ExpandedSection.none;
    });
  }

  void _toggleSection(_ExpandedSection section) {
    HapticController.light();
    setState(() {
      _expandedSection =
          _expandedSection == section ? _ExpandedSection.none : section;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      builder: (context, state) {
        // Auto-hide during drawing.
        final isDrawing = state.isDrawing;
        if (isDrawing && !_wasDrawing) {
          _hideController.reverse();
        } else if (!isDrawing && _wasDrawing) {
          _hideController.forward();
        }
        _wasDrawing = isDrawing;

        return AnimatedBuilder(
          animation: _hideAnimation,
          builder: (context, child) {
            if (_hideAnimation.value == 0.0) {
              return const SizedBox.shrink();
            }
            return Opacity(
              opacity: _hideAnimation.value,
              child: Transform.translate(
                offset: Offset(0, -20 * (1 - _hideAnimation.value)),
                child: child,
              ),
            );
          },
          child: _buildPositioned(context, state),
        );
      },
    );
  }

  Widget _buildPositioned(BuildContext context, CanvasState state) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12 + _position.dy,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(_position.dx, 0),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
                // Clamp horizontal position to keep toolbar on screen.
                _position = Offset(
                  _position.dx.clamp(
                    -(screenWidth / 2) + 40,
                    (screenWidth / 2) - 40,
                  ),
                  _position.dy.clamp(-topPadding, 400),
                );
              });
            },
            child: _collapsed
                ? _buildCollapsedBar(context, state)
                : _buildExpandedBar(context, state),
          ),
        ),
      ),
    );
  }

  // ─── Collapsed (minimal) bar ──────────────────────────────────────────────

  Widget _buildCollapsedBar(BuildContext context, CanvasState state) {
    return _FrostedPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(onDoubleTap: _toggleCollapse),
          const SizedBox(width: 4),
          // Show just the active tool icon + color dot for context.
          Icon(
            _iconForTool(state.activeTool),
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: state.activeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SmallIconButton(
            icon: Icons.expand_more_rounded,
            tooltip: 'Expand toolbar',
            onTap: _toggleCollapse,
          ),
        ],
      ),
    );
  }

  // ─── Expanded (full) bar ──────────────────────────────────────────────────

  Widget _buildExpandedBar(BuildContext context, CanvasState state) {
    final bloc = context.read<CanvasBloc>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Primary toolbar row ──────────────────────────────────────────
        _FrostedPill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(onDoubleTap: _toggleCollapse),
              const SizedBox(width: 2),
              // ── Pen picker ─────────────────────────────────────────────
              _CompactPenPicker(
                activeTool: state.activeTool,
                onToolSelected: (tool) {
                  HapticController.light();
                  bloc.add(ToolChanged(tool));
                },
              ),
              const _ToolbarDivider(),
              // ── Color swatches ─────────────────────────────────────────
              _CompactColorPicker(
                activeColor: state.activeColor,
                onColorSelected: (c) {
                  HapticController.selection();
                  bloc.add(ColorChanged(c));
                },
              ),
              const _ToolbarDivider(),
              // ── Thickness ──────────────────────────────────────────────
              _CompactThicknessControl(
                value: state.activeWidth,
                color: state.activeColor,
                onChanged: (w) => bloc.add(WidthChanged(w)),
              ),
              const _ToolbarDivider(),
              // ── Undo / Redo ────────────────────────────────────────────
              _SmallIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                onTap: state.canUndo
                    ? () {
                        HapticController.light();
                        bloc.add(const UndoRequested());
                      }
                    : null,
              ),
              _SmallIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                onTap: state.canRedo
                    ? () {
                        HapticController.light();
                        bloc.add(const RedoRequested());
                      }
                    : null,
              ),
              const _ToolbarDivider(),
              // ── Effects toggle ─────────────────────────────────────────
              _SmallIconButton(
                icon: state.effectsEnabled
                    ? Icons.auto_awesome
                    : Icons.auto_awesome_outlined,
                tooltip:
                    state.effectsEnabled ? 'Effects On' : 'Effects Off',
                isActive: state.effectsEnabled,
                onTap: () {
                  HapticController.medium();
                  bloc.add(
                      EffectsToggled(enabled: !state.effectsEnabled));
                },
              ),
              const _ToolbarDivider(),
              // ── Tools tray toggle ──────────────────────────────────────
              _SmallIconButton(
                icon: Icons.construction_outlined,
                tooltip: 'More tools',
                isActive: _expandedSection == _ExpandedSection.tools,
                onTap: () => _toggleSection(_ExpandedSection.tools),
              ),
              // ── Insert tray toggle ─────────────────────────────────────
              _SmallIconButton(
                icon: Icons.add_circle_outline,
                tooltip: 'Insert',
                isActive: _expandedSection == _ExpandedSection.insert,
                onTap: () => _toggleSection(_ExpandedSection.insert),
              ),
              const SizedBox(width: 2),
              // ── Collapse handle ────────────────────────────────────────
              _SmallIconButton(
                icon: Icons.expand_less_rounded,
                tooltip: 'Collapse toolbar',
                onTap: _toggleCollapse,
              ),
            ],
          ),
        ),
        // ── Expandable tray ──────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expandedSection == _ExpandedSection.none
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _expandedSection == _ExpandedSection.tools
                      ? _ToolsTray(state: state, bloc: bloc)
                      : _InsertTray(
                          onSettingsTap: widget.onSettingsTap,
                        ),
                ),
        ),
      ],
    );
  }

  IconData _iconForTool(Tool tool) {
    switch (tool.type) {
      case StrokeTool.fountainPen:
        return Icons.create_outlined;
      case StrokeTool.ballpoint:
        return Icons.edit_outlined;
      case StrokeTool.highlighter:
        return Icons.format_color_fill_outlined;
      case StrokeTool.eraser:
        return Icons.auto_fix_normal_outlined;
    }
  }
}

// ─── Frosted pill container ─────────────────────────────────────────────────

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF2C2420).withOpacity(0.78)
        : const Color(0xFFFFFBF6).withOpacity(0.85);
    final borderColor = isDark
        ? const Color(0xFF4A3F38).withOpacity(0.5)
        : const Color(0xFFEDE3D8).withOpacity(0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Drag handle ────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle({this.onDoubleTap});

  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toolbar divider ────────────────────────────────────────────────────────

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.toolbarBorder.withOpacity(0.6),
      );
}

// ─── Small icon button ──────────────────────────────────────────────────────

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? Theme.of(context).disabledColor
        : isActive
            ? AppColors.accent
            : Theme.of(context).colorScheme.onSurface;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: isActive
              ? BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ─── Compact pen picker (just icons, no labels) ─────────────────────────────

class _CompactPenPicker extends StatelessWidget {
  const _CompactPenPicker({
    required this.activeTool,
    required this.onToolSelected,
  });

  final Tool activeTool;
  final void Function(Tool) onToolSelected;

  static const _tools = [
    Tool.defaultFountainPen,
    Tool.defaultBallpoint,
    Tool.defaultHighlighter,
    Tool.defaultEraser,
  ];

  static const _icons = [
    Icons.create_outlined,
    Icons.edit_outlined,
    Icons.format_color_fill_outlined,
    Icons.auto_fix_normal_outlined,
  ];

  static const _labels = ['Pen', 'Ball', 'Highlight', 'Eraser'];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _tools.length,
          (i) {
            final isActive = activeTool.type == _tools[i].type;
            return _SmallIconButton(
              icon: _icons[i],
              tooltip: _labels[i],
              isActive: isActive,
              onTap: () => onToolSelected(_tools[i].copyWith(
                color: activeTool.color,
                baseWidth: activeTool.baseWidth,
              )),
            );
          },
        ),
      );
}

// ─── Compact color picker (4 most-used + custom) ────────────────────────────

class _CompactColorPicker extends StatelessWidget {
  const _CompactColorPicker({
    required this.activeColor,
    required this.onColorSelected,
  });

  final Color activeColor;
  final void Function(Color) onColorSelected;

  @override
  Widget build(BuildContext context) {
    // Show first 4 preset colors + a "more" ring.
    final presets = AppColors.defaultPenColors.take(4).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...presets.map((c) => _MiniSwatch(
              color: c,
              isSelected: activeColor.value == c.value,
              onTap: () => onColorSelected(c),
            )),
        _MiniSwatch(
          color: activeColor,
          isSelected: !presets.any((c) => c.value == activeColor.value),
          isCustom: true,
          onTap: () => _showFullColorPicker(context),
        ),
      ],
    );
  }

  void _showFullColorPicker(BuildContext context) {
    showDialog<Color>(
      context: context,
      builder: (_) => _FullColorDialog(initial: activeColor),
    ).then((picked) {
      if (picked != null) onColorSelected(picked);
    });
  }
}

class _MiniSwatch extends StatelessWidget {
  const _MiniSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isCustom = false,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isCustom ? null : color,
          gradient: isCustom
              ? const SweepGradient(colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.cyan,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ])
              : null,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: AppColors.accent,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
        ),
        transform: isSelected
            ? (Matrix4.identity()..scale(1.15))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
      ),
    );
  }
}

/// Full-palette color dialog reused from color_picker.dart pattern.
class _FullColorDialog extends StatefulWidget {
  const _FullColorDialog({required this.initial});
  final Color initial;

  @override
  State<_FullColorDialog> createState() => _FullColorDialogState();
}

class _FullColorDialogState extends State<_FullColorDialog> {
  late Color _selected;

  static const _palette = [
    ...AppColors.defaultPenColors,
    Colors.white,
    Color(0xFFBDBDBD),
    Color(0xFF795548),
    Color(0xFF009688),
    Color(0xFF8BC34A),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF03A9F4),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFF4CAF50),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFFF44336),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Choose Color'),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette
                .map((c) => GestureDetector(
                      onTap: () => setState(() => _selected = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: _selected.value == c.value
                              ? Border.all(
                                  color: AppColors.accent,
                                  width: 3,
                                  strokeAlign:
                                      BorderSide.strokeAlignOutside,
                                )
                              : null,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Select'),
          ),
        ],
      );
}

// ─── Compact thickness control ──────────────────────────────────────────────

class _CompactThicknessControl extends StatefulWidget {
  const _CompactThicknessControl({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final double value;
  final Color color;
  final void Function(double) onChanged;

  @override
  State<_CompactThicknessControl> createState() =>
      _CompactThicknessControlState();
}

class _CompactThicknessControlState extends State<_CompactThicknessControl> {
  bool _showSlider = false;

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.value.clamp(4.0, 16.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dot preview — tap to toggle slider.
        GestureDetector(
          onTap: () => setState(() => _showSlider = !_showSlider),
          child: Tooltip(
            message: 'Thickness: ${widget.value.toStringAsFixed(1)}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: dotSize * 0.3,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Inline slider — slides in/out.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: _showSlider
              ? SizedBox(
                  width: 100,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: widget.value,
                      min: AppConstants.minStrokeWidth,
                      max: AppConstants.maxStrokeWidth,
                      onChanged: widget.onChanged,
                      activeColor: AppColors.accent,
                      thumbColor: widget.color,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Tools tray (shapes, recognition, drawing tools, settings) ──────────────

class _ToolsTray extends StatelessWidget {
  const _ToolsTray({required this.state, required this.bloc});

  final CanvasState state;
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) {
    return _FrostedPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Auto-shape recognition.
          _SmallIconButton(
            icon: Icons.auto_fix_high,
            tooltip: state.autoShapeRecognition
                ? 'Auto-shape ON'
                : 'Auto-shape OFF',
            isActive: state.autoShapeRecognition,
            onTap: () {
              HapticController.light();
              bloc.add(AutoShapeRecognitionToggled(
                  enabled: !state.autoShapeRecognition));
            },
          ),
          // Shape tool.
          _SmallIconButton(
            icon: Icons.category_outlined,
            tooltip: state.isShapeMode ? 'Exit shape mode' : 'Shape tools',
            isActive: state.isShapeMode,
            onTap: () {
              HapticController.light();
              if (state.isShapeMode) {
                bloc.add(const ShapeToolDeactivated());
              } else {
                _showShapePicker(context);
              }
            },
          ),
          const _ToolbarDivider(),
          // Drawing tool picker.
          _SmallIconButton(
            icon: state.activeDrawingTool?.icon ?? Icons.brush_outlined,
            tooltip: state.activeDrawingTool?.name ?? 'Tools',
            onTap: () {
              HapticController.light();
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<CanvasBloc>(),
                  child: const ToolPickerPanel(),
                ),
              );
            },
          ),
          // Tool settings.
          _SmallIconButton(
            icon: Icons.tune,
            tooltip: 'Tool settings',
            onTap: () {
              HapticController.light();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => BlocProvider.value(
                  value: context.read<CanvasBloc>(),
                  child: const ToolSettingsPanel(),
                ),
              );
            },
          ),
          const _ToolbarDivider(),
          // Handwriting recognition.
          const _RecognizeSmallButton(),
          const _ToolbarDivider(),
          // Share.
          _SmallIconButton(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            onTap: () {
              HapticController.light();
              // Delegate to the ShareButton's action.
              showDialog<void>(
                context: context,
                builder: (_) => const Dialog(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ShareButton(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showShapePicker(BuildContext context) {
    showDialog<ShapeType>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose a shape',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ShapeTypePicker(
                selected: state.activeShapeType,
                onSelected: (type) {
                  Navigator.of(context).pop(type);
                  bloc.add(ShapeToolActivated(type));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Insert tray (templates, widgets, stickers, media, etc.) ────────────────

class _InsertTray extends StatelessWidget {
  const _InsertTray({this.onSettingsTap});

  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return _FrostedPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Templates.
          _SmallIconButton(
            icon: Icons.dashboard_customize_outlined,
            tooltip: 'Templates',
            onTap: () {
              HapticController.light();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: context.read<TemplateBloc>(),
                  child: TemplatePicker(
                    onApply: (NoteTemplate t) {
                      context
                          .read<TemplateBloc>()
                          .add(TemplateApplied(t.id));
                    },
                  ),
                ),
              );
            },
          ),
          // Smart Widgets.
          _SmallIconButton(
            icon: Icons.widgets_outlined,
            tooltip: 'Widgets',
            onTap: () {
              HapticController.light();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: context.read<WidgetBloc>(),
                  child: WidgetPickerPanel(
                    onSelected: (w) {
                      context.read<WidgetBloc>().add(WidgetAdded(w));
                    },
                  ),
                ),
              );
            },
          ),
          // Stickers.
          _SmallIconButton(
            icon: Icons.emoji_emotions_outlined,
            tooltip: 'Stickers',
            onTap: () {
              HapticController.light();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: context.read<StickerBloc>(),
                  child: StickerPickerPanel(
                    onSelected: (template) {
                      Navigator.of(context).pop();
                      context
                          .read<StickerBloc>()
                          .add(StickerPlacementPending(template));
                    },
                  ),
                ),
              );
            },
          ),
          const _ToolbarDivider(),
          // Media.
          _SmallIconButton(
            icon: Icons.play_circle_outline,
            tooltip: 'Media',
            onTap: () {
              HapticController.light();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: context.read<MediaBloc>(),
                  child: MediaPickerPanel(
                    onSelected: (element) {
                      context
                          .read<MediaBloc>()
                          .add(MediaAdded(element));
                    },
                  ),
                ),
              );
            },
          ),
          // Rich Text.
          _SmallIconButton(
            icon: Icons.text_fields,
            tooltip: 'Rich Text',
            onTap: () {
              HapticController.light();
              context.read<RichTextBloc>().add(
                    const CreateRichTextElement(
                      position: Offset(100, 100),
                    ),
                  );
            },
          ),
          // Math Graph.
          _SmallIconButton(
            icon: Icons.show_chart,
            tooltip: 'Math Graph',
            onTap: () {
              HapticController.light();
              context.read<GraphBloc>().add(
                    GraphCreated(
                      bounds: const Rect.fromLTWH(50, 50, 400, 300),
                    ),
                  );
            },
          ),
          const _ToolbarDivider(),
          // Document actions (export/import).
          _SmallIconButton(
            icon: Icons.folder_outlined,
            tooltip: 'Document Actions',
            onTap: () {
              HapticController.light();
              // Open document export/import via the existing panel.
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<CanvasBloc>(),
                  child: const DocumentToolbarActions(),
                ),
              );
            },
          ),
          // Scanner.
          _SmallIconButton(
            icon: Icons.document_scanner_outlined,
            tooltip: 'Scan Document',
            onTap: () {
              HapticController.light();
              context.go('/scanner');
            },
          ),
          const _ToolbarDivider(),
          // Settings.
          _SmallIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () {
              HapticController.light();
              onSettingsTap?.call();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Recognize button (compact) ─────────────────────────────────────────────

class _RecognizeSmallButton extends StatelessWidget {
  const _RecognizeSmallButton();

  @override
  Widget build(BuildContext context) {
    HandwritingBloc? hwBloc;
    HandwritingState? hwState;
    try {
      hwBloc = context.watch<HandwritingBloc>();
      hwState = hwBloc.state;
    } on Exception {
      // Not yet in tree.
    }

    final isProcessing = hwState?.isProcessing ?? false;

    return _SmallIconButton(
      icon: Icons.auto_fix_high_outlined,
      tooltip: 'Recognize handwriting',
      onTap: isProcessing
          ? null
          : () {
              HapticController.medium();
              if (hwBloc != null) {
                final canvasState = context.read<CanvasBloc>().state;
                hwBloc.add(RecognitionRequested(
                  strokes: canvasState.strokes,
                ));
              }
            },
    );
  }
}
