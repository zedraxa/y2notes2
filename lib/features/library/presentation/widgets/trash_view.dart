import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_event.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_state.dart';

/// Shows items currently in the trash with restore / permanent-delete options.
class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        actions: [
          BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              if (state.trashItems.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmEmptyTrash(context),
                child: const Text(
                  'Empty Trash',
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          final trashed = state.trashItems;

          if (trashed.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Trash is empty',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: trashed.length,
            itemBuilder: (context, index) {
              final item = trashed[index];
              final daysSinceDeletion = item.trashedAt == null
                  ? 0
                  : DateTime.now().difference(item.trashedAt!).inDays;
              final daysLeft = (30 - daysSinceDeletion).clamp(0, 30);

              return ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(item.name),
                subtitle: Text(
                  'Deleted ${daysSinceDeletion}d ago \u00b7 auto-delete in ${daysLeft}d',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restore',
                      onPressed: () => context
                          .read<LibraryBloc>()
                          .add(RestoreItem(item.id)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Delete permanently',
                      onPressed: () =>
                          _confirmPermanentDelete(context, item.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All items in the trash will be permanently deleted. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<LibraryBloc>().add(const EmptyTrash());
    }
  }

  Future<void> _confirmPermanentDelete(
      BuildContext context, String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<LibraryBloc>().add(PermanentlyDeleteItem(itemId));
    }
  }
}
