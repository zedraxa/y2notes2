import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';
import 'package:biscuits/features/library/presentation/widgets/color_label_picker.dart';
import 'package:biscuits/features/library/presentation/widgets/cover_picker_bottom_sheet.dart';

/// Context menu (bottom sheet) for a single [LibraryItem].
///
/// Shows common actions: rename, move, favourite, colour label, trash.
class ItemContextMenu extends StatelessWidget {
  const ItemContextMenu({super.key, required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LibraryBloc>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Item name header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            // Favourite
            ListTile(
              leading: Icon(
                item.isFavorite ? Icons.star : Icons.star_outline,
                color: item.isFavorite ? Colors.amber : null,
              ),
              title:
                  Text(item.isFavorite ? 'Remove from Favourites' : 'Favourite'),
              onTap: () {
                bloc.add(ToggleFavorite(item.id));
                Navigator.pop(context);
              },
            ),
            // Rename
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, bloc);
              },
            ),
            // Customise cover (notebooks only)
            if (item.type == LibraryItemType.notebook)
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Customise Cover'),
                onTap: () {
                  Navigator.pop(context);
                  CoverPickerBottomSheet.show(context, item);
                },
              ),
            // Move to folder
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                _showMoveDialog(context, bloc);
              },
            ),
            // Colour label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colour Label',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  ColorLabelPicker(
                    selected: item.colorLabel,
                    onSelect: (label) {
                      bloc.add(SetColorLabel(
                          itemId: item.id, colorLabel: label));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            // Move to trash
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Move to Trash',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                bloc.add(DeleteItem(item.id));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, LibraryBloc bloc) {
    final controller = TextEditingController(text: item.name);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (_) {
            _submitRename(context, bloc, controller.text.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                _submitRename(context, bloc, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _submitRename(BuildContext context, LibraryBloc bloc, String name) {
    if (name.isNotEmpty) bloc.add(RenameItem(itemId: item.id, newName: name));
    Navigator.pop(context);
  }

  void _showMoveDialog(BuildContext context, LibraryBloc bloc) {
    final state = bloc.state;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Move to…',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Root (Library)'),
              onTap: () {
                bloc.add(MoveToFolder(itemId: item.id, folderId: null));
                Navigator.pop(context);
              },
            ),
            ...state.folders.map((folder) => ListTile(
                  leading: Text(folder.emoji ?? '📁',
                      style: const TextStyle(fontSize: 20)),
                  title: Text(folder.name),
                  onTap: () {
                    bloc.add(MoveToFolder(
                        itemId: item.id, folderId: folder.id));
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
