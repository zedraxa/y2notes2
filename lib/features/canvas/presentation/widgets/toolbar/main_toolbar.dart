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
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/tool_picker_panel.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/tool_settings_panel.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_state.dart';

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
                // ── Plugin tool picker ─────────────────────────────────────
                _ToolPickerButton(state: state),
                const _Divider(),
                // ── Tool-specific settings ─────────────────────────────────
                _ToolSettingsButton(state: state),
                const _Divider(),
                // ── Undo / Redo ────────────────────────────────────────────
                _UndoRedoButtons(state: state, bloc: bloc),
                const Spacer(),
                // ── Recognize (handwriting → text) ───────────────────────
                _RecognizeButton(),
                const _Divider(),
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

/// Recognize button — taps to trigger handwriting recognition on all strokes.
class _RecognizeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // HandwritingBloc is provided at the app root (see main.dart).
    // Use watch so the button rebuilds when processing state changes.
    HandwritingBloc? hwBloc;
    HandwritingState? hwState;
    try {
      hwBloc = context.watch<HandwritingBloc>();
      hwState = hwBloc.state;
    } on Exception {
      // HandwritingBloc not yet in tree.
    }

    final isProcessing = hwState?.isProcessing ?? false;

    return IconButton(
      icon: isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_fix_high_outlined),
      iconSize: AppConstants.toolbarIconSize,
      tooltip: 'Recognize handwriting',
      onPressed: isProcessing
          ? null
          : () {
              HapticController.medium();
              if (hwBloc != null) {
                // Pass current canvas strokes to the recognition event.
                final canvasState = context.read<CanvasBloc>().state;
                hwBloc.add(RecognitionRequested(
                  strokes: canvasState.strokes,
                ));
              }
            },
    );
  }
}
