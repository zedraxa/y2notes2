import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/stickers/domain/entities/sticker_element.dart';
import 'package:biscuits/features/stickers/engine/stamp_brush_engine.dart';
import 'package:biscuits/features/stickers/engine/sticker_hit_tester.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_event.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_state.dart';
import 'package:biscuits/features/stickers/presentation/widgets/sticker_context_menu.dart';

/// Overlay widget that handles pointer events for sticker placement & interaction.
class StickerInteractionHandler extends StatefulWidget {
  const StickerInteractionHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StickerInteractionHandler> createState() =>
      _StickerInteractionHandlerState();
}

class _StickerInteractionHandlerState
    extends State<StickerInteractionHandler> {
  Offset? _dragStart;
  String? _draggingId;
  Offset? _dragStartStickerPosition;
  StampBrushEngine? _brushEngine;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StickerBloc, StickerState>(
        builder: (context, state) {
          final isPlacing = state.pendingPlacement != null;
          final isBrushing = state.isStampBrushActive;

          return MouseRegion(
            cursor: isPlacing || isBrushing
                ? SystemMouseCursors.precise
                : MouseCursor.defer,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) => _onTapDown(details, state),
              onLongPressStart: (details) =>
                  _onLongPress(details, state, context),
              onPanStart: (details) => _onPanStart(details, state),
              onPanUpdate: (details) => _onPanUpdate(details, state),
              onPanEnd: (_) => _onPanEnd(state),
              child: widget.child,
            ),
          );
        },
      );

  void _onTapDown(TapDownDetails details, StickerState state) {
    final bloc = context.read<StickerBloc>();
    final pos = details.localPosition;

    // Placement mode: place the pending sticker
    if (state.pendingPlacement != null) {
      final placed = StickerElement(
        type: state.pendingPlacement!.type,
        assetKey: state.pendingPlacement!.assetKey,
        position: pos,
        scale: state.pendingPlacement!.scale,
        rotation: state.pendingPlacement!.rotation,
        opacity: state.pendingPlacement!.opacity,
        washiLength: state.pendingPlacement!.washiLength,
        washiWidth: state.pendingPlacement!.washiWidth,
        washiTint: state.pendingPlacement!.washiTint,
      );
      bloc.add(StickerPlaced(placed));
      return;
    }

    // Normal mode: select / deselect
    final hit = StickerHitTester.hitTest(state.stickers, pos);
    bloc.add(StickerSelected(hit?.id));
  }

  void _onLongPress(
      LongPressStartDetails details, StickerState state, BuildContext context) {
    final hit =
        StickerHitTester.hitTest(state.stickers, details.localPosition);
    if (hit == null) return;

    context.read<StickerBloc>().add(StickerSelected(hit.id));

    showStickerContextMenu(
      context: context,
      position: details.globalPosition,
      stickerId: hit.id,
      isLocked: hit.isLocked,
    );
  }

  void _onPanStart(DragStartDetails details, StickerState state) {
    // Stamp brush mode: start painting trail
    if (state.isStampBrushActive) {
      _brushEngine = StampBrushEngine(stampId: state.stampBrushId!);
      _brushEngine!.onDragStart(details.localPosition);
      return;
    }

    if (state.pendingPlacement != null) return;
    final hit =
        StickerHitTester.hitTest(state.stickers, details.localPosition);
    if (hit == null) return;

    _draggingId = hit.id;
    _dragStart = details.localPosition;
    _dragStartStickerPosition = hit.position;
    context.read<StickerBloc>().add(StickerSelected(hit.id));
  }

  void _onPanUpdate(DragUpdateDetails details, StickerState state) {
    // Stamp brush mode: continue painting trail
    if (_brushEngine != null) {
      _brushEngine!.onDragUpdate(details.localPosition);
      return;
    }

    if (_draggingId == null ||
        _dragStart == null ||
        _dragStartStickerPosition == null) {
      return;
    }
    final delta = details.localPosition - _dragStart!;
    final newPos = _dragStartStickerPosition! + delta;
    context.read<StickerBloc>().add(StickerMoved(_draggingId!, newPos));
  }

  void _onPanEnd(StickerState state) {
    // Stamp brush mode: finalize trail
    if (_brushEngine != null) {
      final trail = _brushEngine!.onDragEnd();
      if (trail.isNotEmpty) {
        context.read<StickerBloc>().add(StampBrushTrailPlaced(trail));
      }
      _brushEngine = null;
      return;
    }

    _draggingId = null;
    _dragStart = null;
    _dragStartStickerPosition = null;
  }
}
