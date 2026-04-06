import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/engine/haptic_controller.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/color_picker.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/effects_toggle.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/pen_picker.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/thickness_slider.dart';

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
                // ── Undo / Redo ────────────────────────────────────────────
                _UndoRedoButtons(state: state, bloc: bloc),
                const Spacer(),
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
