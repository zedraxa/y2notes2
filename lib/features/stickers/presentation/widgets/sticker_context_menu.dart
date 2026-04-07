import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuitse/features/stickers/presentation/bloc/sticker_event.dart';

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

enum _ContextMenuAction {
  duplicate,
  delete,
  lock,
  bringToFront,
  sendToBack,
  bringForward,
  sendBackward,
}
