import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/engine/haptic_controller.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/color_picker.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/effects_toggle.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/pen_picker.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/thickness_slider.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/tool_picker_panel.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/tool_settings_panel.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_type.dart';
import 'package:y2notes2/features/shapes/presentation/widgets/shape_type_picker.dart';

/// GoodNotes-style thin top toolbar.
class MainToolbar extends StatelessWidget {
  const MainToolbar({super.key, this.onSettingsTap});

  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CanvasBloc, CanvasState>(
        builder: (context, state) {
          final bloc = context.read<CanvasBloc>();

          return Container(
            height: AppConstants.toolbarHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.toolbarBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // ── Pen type selector ──────────────────────────────────────
                PenPicker(
                  activeTool: state.activeTool,
                  onToolSelected: (tool) {
                    HapticController.light();
                    bloc.add(ToolChanged(tool));
                  },
                ),
                const _Divider(),
                // ── Color palette ──────────────────────────────────────────
                ColorPicker(
                  activeColor: state.activeColor,
                  onColorSelected: (color) {
                    HapticController.selection();
                    bloc.add(ColorChanged(color));
                  },
                ),
                const _Divider(),
                // ── Thickness slider ───────────────────────────────────────
                ThicknessSlider(
                  value: state.activeWidth,
                  onChanged: (w) => bloc.add(WidthChanged(w)),
                  color: state.activeColor,
                ),
                const _Divider(),
                // ── Effects toggle ─────────────────────────────────────────
                EffectsToggle(
                  enabled: state.effectsEnabled,
                  onToggle: (v) {
                    HapticController.medium();
                    bloc.add(EffectsToggled(enabled: v));
                  },
                ),
                const _Divider(),
                // ── Auto-shape recognition toggle ──────────────────────────
                _AutoShapeToggle(state: state, bloc: bloc),
                const _Divider(),
                // ── Shape tool picker ──────────────────────────────────────
                _ShapeToolButton(state: state, bloc: bloc),
                const _Divider(),
                // ── Plugin tool picker ─────────────────────────────────────
                _ToolPickerButton(state: state),
                const _Divider(),
                // ── Tool-specific settings ─────────────────────────────────
                _ToolSettingsButton(state: state),
                const _Divider(),
                // ── Undo / Redo ────────────────────────────────────────────
                _UndoRedoButtons(state: state, bloc: bloc),
                const Spacer(),
                // ── Stylus indicator ───────────────────────────────────────
                _StylusIndicator(state: state),
                // ── Settings ──────────────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  iconSize: AppConstants.toolbarIconSize,
                  onPressed: () {
                    HapticController.light();
                    onSettingsTap?.call();
                  },
                  tooltip: 'Settings',
                ),
                const SizedBox(width: 4),
              ],
            ),
          );
        },
      );
}

class _UndoRedoButtons extends StatelessWidget {
  const _UndoRedoButtons({required this.state, required this.bloc});

  final CanvasState state;
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            iconSize: AppConstants.toolbarIconSize,
            onPressed: state.canUndo
                ? () {
                    HapticController.light();
                    bloc.add(const UndoRequested());
                  }
                : null,
            tooltip: 'Undo',
            color: state.canUndo
                ? null
                : Theme.of(context).disabledColor,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            iconSize: AppConstants.toolbarIconSize,
            onPressed: state.canRedo
                ? () {
                    HapticController.light();
                    bloc.add(const RedoRequested());
                  }
                : null,
            tooltip: 'Redo',
            color: state.canRedo
                ? null
                : Theme.of(context).disabledColor,
          ),
        ],
      );
}

class _ToolPickerButton extends StatelessWidget {
  const _ToolPickerButton({required this.state});

  final CanvasState state;

  @override
  Widget build(BuildContext context) {
    final activeTool = state.activeDrawingTool;
    return IconButton(
      icon: Icon(activeTool?.icon ?? Icons.brush_outlined),
      iconSize: AppConstants.toolbarIconSize,
      tooltip: activeTool?.name ?? 'Tools',
      onPressed: () {
        HapticController.light();
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<CanvasBloc>(),
            child: const ToolPickerPanel(),
          ),
        );
      },
    );
  }
}

class _ToolSettingsButton extends StatelessWidget {
  const _ToolSettingsButton({required this.state});

  final CanvasState state;

  @override
  Widget build(BuildContext context) {
    final tool = state.activeDrawingTool;
    final hasSettings = tool != null && tool.settingsSchema.isNotEmpty;
    return IconButton(
      icon: const Icon(Icons.tune),
      iconSize: AppConstants.toolbarIconSize,
      tooltip: hasSettings ? '${tool.name} settings' : 'Tool settings',
      onPressed: () {
        HapticController.light();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => BlocProvider.value(
            value: context.read<CanvasBloc>(),
            child: const ToolSettingsPanel(),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.toolbarBorder,
      );
}

/// Toggle button for auto-shape recognition.
class _AutoShapeToggle extends StatelessWidget {
  const _AutoShapeToggle({required this.state, required this.bloc});

  final CanvasState state;
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: state.autoShapeRecognition
          ? 'Auto-shape ON'
          : 'Auto-shape OFF',
      child: GestureDetector(
        onTap: () {
          HapticController.light();
          bloc.add(AutoShapeRecognitionToggled(
              enabled: !state.autoShapeRecognition));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: state.autoShapeRecognition
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_fix_high,
                size: AppConstants.toolbarIconSize,
                color: state.autoShapeRecognition
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 2),
              Text(
                'Shape',
                style: TextStyle(
                  fontSize: 10,
                  color: state.autoShapeRecognition
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Button that opens the shape type picker to start explicit shape drawing.
class _ShapeToolButton extends StatelessWidget {
  const _ShapeToolButton({required this.state, required this.bloc});

  final CanvasState state;
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) {
    final isActive = state.isShapeMode;
    return IconButton(
      icon: Icon(
        Icons.category_outlined,
        color: isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      iconSize: AppConstants.toolbarIconSize,
      tooltip: isActive ? 'Exit shape mode' : 'Shape tools',
      onPressed: () {
        HapticController.light();
        if (isActive) {
          bloc.add(const ShapeToolDeactivated());
        } else {
          _showShapePicker(context);
        }
      },
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

/// Small indicator in the toolbar showing the connected stylus type.
///
/// Shows a stylus icon with a coloured dot when a non-generic stylus is
/// detected.  Tapping it navigates to `/settings/stylus`.
class _StylusIndicator extends StatelessWidget {
  const _StylusIndicator({required this.state});

  final CanvasState state;

  @override
  Widget build(BuildContext context) {
    final type = state.detectedStylusType;
    final isKnown = type != StylusType.unknown &&
        type != StylusType.finger &&
        type != StylusType.generic;

    return IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.draw_outlined,
              size: AppConstants.toolbarIconSize,
              color: isKnown
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
            if (isKnown)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        iconSize: AppConstants.toolbarIconSize,
        tooltip: isKnown ? _labelFor(type) : 'Stylus settings',
        onPressed: () {
          HapticController.light();
          // Navigate to stylus settings page
        },
      );
  }

  static String _labelFor(StylusType type) {
    switch (type) {
      case StylusType.applePencil:
        return 'Apple Pencil';
      case StylusType.applePencil2:
        return 'Apple Pencil 2nd Gen';
      case StylusType.applePencilPro:
        return 'Apple Pencil Pro';
      case StylusType.samsungSPen:
        return 'Samsung S Pen';
      case StylusType.usiPen:
        return 'USI Pen';
      case StylusType.wacomEmr:
        return 'Wacom Pen';
      case StylusType.generic:
        return 'Generic Stylus';
      case StylusType.finger:
      case StylusType.unknown:
        return 'No stylus';
    }
  }
}
