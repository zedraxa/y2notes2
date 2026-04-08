import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';
import 'package:biscuits/features/library/presentation/widgets/item_context_menu.dart';

/// Displays library items as a scrollable list.
class LibraryList extends StatelessWidget {
  const LibraryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        final items = state.isSearching
            ? state.searchResults.map((r) => r.item).toList()
            : state.visibleItems;

        if (items.isEmpty) {
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
                    state.isSearching
                        ? Icons.search_off_outlined
                        : Icons.folder_open_outlined,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.isSearching ? 'No results found' : 'No items here yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.5),
                      ),
                ),
                if (!state.isSearching) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to create your first notebook',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.4),
                        ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) =>
              _LibraryListTile(item: items[index]),
        );
      },
    );
  }
}

class _LibraryListTile extends StatelessWidget {
  const _LibraryListTile({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final colorLabel = item.colorLabel?.color;

    return Semantics(
      label: '${_typeLabel(item.type)}: ${item.name}, '
          'modified ${_subtitle(item)}'
          '${item.isFavorite ? ", favourited" : ""}',
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                _iconFor(item.type),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (colorLabel != null)
              Positioned(
                bottom: 0,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorLabel,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _subtitle(item),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isFavorite)
              const Icon(Icons.star, size: 16, color: Colors.amber),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'More actions',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => ItemContextMenu(item: item),
              ),
            ),
          ],
        ),
        onTap: () {/* Navigate to item — handled by parent page */},
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => ItemContextMenu(item: item),
        ),
      ),
    );
  }

  String _subtitle(LibraryItem item) {
    final diff = DateTime.now().difference(item.updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconFor(LibraryItemType type) {
    switch (type) {
      case LibraryItemType.notebook:
        return Icons.menu_book_outlined;
      case LibraryItemType.infiniteCanvas:
        return Icons.dashboard_outlined;
      case LibraryItemType.folder:
        return Icons.folder_outlined;
    }
  }

  String _typeLabel(LibraryItemType type) {
    switch (type) {
      case LibraryItemType.notebook:
        return 'Notebook';
      case LibraryItemType.infiniteCanvas:
        return 'Canvas';
      case LibraryItemType.folder:
        return 'Folder';
    }
  }
}
