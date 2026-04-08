import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';
import 'package:biscuits/features/library/presentation/widgets/item_context_menu.dart';

/// Displays library items in a responsive grid layout.
class LibraryGrid extends StatelessWidget {
  const LibraryGrid({super.key});

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
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, child) => Opacity(
                    opacity: value,
                    child: child,
                  ),
                  child: Text(
                    state.isSearching ? 'No results found' : 'No items here yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                  ),
                ),
                if (!state.isSearching) ...[
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                    child: Text(
                      'Create a notebook to get started',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                          ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _LibraryGridCard(item: items[index]),
        );
      },
    );
  }
}

class _LibraryGridCard extends StatelessWidget {
  const _LibraryGridCard({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final colorLabel = item.colorLabel?.color;
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail / placeholder
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumbnailPath != null)
                    Image.asset(item.thumbnailPath!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        _iconFor(item.type),
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  // Color label stripe
                  if (colorLabel != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 4, color: colorLabel),
                    ),
                  // Favourite indicator
                  if (item.isFavorite)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.star, size: 16, color: Colors.amber),
                    ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ItemContextMenu(item: item),
    );
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
}
