import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';
import 'package:biscuits/shared/widgets/apple_toast.dart';
import 'package:biscuits/shared/widgets/confirm_action.dart';

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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      Icons.delete_sweep_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trash is empty',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deleted items will appear here for 30 days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.4),
                        ),
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
    final confirm = await confirmAction(
      context: context,
      title: 'Empty Trash?',
      message: 'All items in the trash will be permanently deleted. '
          'This action cannot be undone.',
      confirmLabel: 'Empty Trash',
      isDestructive: true,
    );
    if (confirm == true && context.mounted) {
      context.read<LibraryBloc>().add(const EmptyTrash());
      AppleToast.show(
        context,
        message: 'Trash emptied',
        style: AppleToastStyle.success,
      );
    }
  }

  Future<void> _confirmPermanentDelete(
      BuildContext context, String itemId) async {
    final confirm = await confirmAction(
      context: context,
      title: 'Delete Permanently?',
      message: 'This item will be gone forever. This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirm == true && context.mounted) {
      context.read<LibraryBloc>().add(PermanentlyDeleteItem(itemId));
      AppleToast.show(
        context,
        message: 'Item permanently deleted',
        style: AppleToastStyle.success,
      );
    }
  }
}
