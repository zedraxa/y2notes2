import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_event.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_state.dart';

Future<void> showStickerContextMenu({
  required BuildContext context,
  required Offset position,
  required String stickerId,
  required bool isLocked,
}) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject()! as RenderBox;

  final selected = await showMenu<_ContextMenuAction>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      const PopupMenuItem(
        value: _ContextMenuAction.duplicate,
        child: ListTile(
          leading: Icon(Icons.copy),
          title: Text('Duplicate'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: _ContextMenuAction.delete,
        child: ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text('Delete'),
          dense: true,
        ),
      ),
      PopupMenuItem(
        value: _ContextMenuAction.lock,
        child: ListTile(
          leading: Icon(isLocked ? Icons.lock_open_outlined : Icons.lock_outline),
          title: Text(isLocked ? 'Unlock' : 'Lock'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: _ContextMenuAction.opacity,
        child: ListTile(
          leading: Icon(Icons.opacity),
          title: Text('Opacity…'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: _ContextMenuAction.bringToFront,
        child: ListTile(
          leading: Icon(Icons.flip_to_front),
          title: Text('Bring to Front'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: _ContextMenuAction.sendToBack,
        child: ListTile(
          leading: Icon(Icons.flip_to_back),
          title: Text('Send to Back'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: _ContextMenuAction.bringForward,
        child: ListTile(
          leading: Icon(Icons.arrow_upward),
          title: Text('Bring Forward'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: _ContextMenuAction.sendBackward,
        child: ListTile(
          leading: Icon(Icons.arrow_downward),
          title: Text('Send Backward'),
          dense: true,
        ),
      ),
    ],
  );

  if (selected == null || !context.mounted) return;
  final bloc = context.read<StickerBloc>();

  switch (selected) {
    case _ContextMenuAction.duplicate:
      bloc.add(StickerDuplicated(stickerId));
    case _ContextMenuAction.delete:
      bloc.add(StickerDeleted(stickerId));
    case _ContextMenuAction.lock:
      bloc.add(StickerLocked(stickerId, isLocked: !isLocked));
    case _ContextMenuAction.opacity:
      if (context.mounted) {
        _showOpacitySlider(context: context, stickerId: stickerId);
      }
    case _ContextMenuAction.bringToFront:
      bloc.add(StickerLayerChanged(stickerId, LayerDirection.front));
    case _ContextMenuAction.sendToBack:
      bloc.add(StickerLayerChanged(stickerId, LayerDirection.back));
    case _ContextMenuAction.bringForward:
      bloc.add(StickerLayerChanged(stickerId, LayerDirection.forward));
    case _ContextMenuAction.sendBackward:
      bloc.add(StickerLayerChanged(stickerId, LayerDirection.backward));
  }
}

void _showOpacitySlider({
  required BuildContext context,
  required String stickerId,
}) {
  final bloc = context.read<StickerBloc>();
  final sticker = bloc.state.stickers.where((s) => s.id == stickerId).firstOrNull;
  if (sticker == null) return;

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _OpacitySliderSheet(
      initialOpacity: sticker.opacity,
      onChanged: (opacity) {
        bloc.add(StickerOpacityChanged(stickerId, opacity));
      },
    ),
  );
}

class _OpacitySliderSheet extends StatefulWidget {
  const _OpacitySliderSheet({
    required this.initialOpacity,
    required this.onChanged,
  });

  final double initialOpacity;
  final ValueChanged<double> onChanged;

  @override
  State<_OpacitySliderSheet> createState() => _OpacitySliderSheetState();
}

class _OpacitySliderSheetState extends State<_OpacitySliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialOpacity;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.opacity, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Opacity: ${(_value * 100).round()}%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _value,
              min: 0.05,
              max: 1.0,
              // 19 divisions = 5% increments (0.05 step size)
              divisions: 19,
              label: '${(_value * 100).round()}%',
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
          ],
        ),
      );
}

enum _ContextMenuAction {
  duplicate,
  delete,
  lock,
  opacity,
  bringToFront,
  sendToBack,
  bringForward,
  sendBackward,
}
