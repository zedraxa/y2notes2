import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';

/// Sort + filter toolbar shown above the library item grid/list.
class SortFilterBar extends StatelessWidget {
  const SortFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Sort menu
              _SortButton(current: state.sortOrder),
              const SizedBox(width: 8),
              // Filter chips
              if (state.hasActiveFilters)
                ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Clear filters'),
                  onPressed: () =>
                      context.read<LibraryBloc>().add(const ClearFilters()),
                ),
              const Spacer(),
              // View mode toggle
              IconButton(
                icon: Icon(
                  state.viewMode == LibraryViewMode.grid
                      ? Icons.view_list
                      : Icons.grid_view,
                ),
                tooltip: state.viewMode == LibraryViewMode.grid
                    ? 'List view'
                    : 'Grid view',
                onPressed: () =>
                    context.read<LibraryBloc>().add(const ToggleViewMode()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.current});

  final LibrarySortOrder current;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LibrarySortOrder>(
      initialValue: current,
      onSelected: (order) =>
          context.read<LibraryBloc>().add(SortBy(order)),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: LibrarySortOrder.dateModified,
          child: Text('Date Modified'),
        ),
        PopupMenuItem(
          value: LibrarySortOrder.dateCreated,
          child: Text('Date Created'),
        ),
        PopupMenuItem(
          value: LibrarySortOrder.name,
          child: Text('Name'),
        ),
        PopupMenuItem(
          value: LibrarySortOrder.size,
          child: Text('Size'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort, size: 18),
          const SizedBox(width: 4),
          Text(_label(current),
              style: Theme.of(context).textTheme.bodySmall),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  String _label(LibrarySortOrder order) {
    switch (order) {
      case LibrarySortOrder.dateModified:
        return 'Modified';
      case LibrarySortOrder.dateCreated:
        return 'Created';
      case LibrarySortOrder.name:
        return 'Name';
      case LibrarySortOrder.size:
        return 'Size';
    }
  }
}

/// A bottom-sheet filter panel for tags, types, and color labels.
class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Filters', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Type',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: LibraryItemType.values.map((type) {
                    final selected = state.filterTypes.contains(type);
                    return ChoiceChip(
                      label: Text(_typeName(type)),
                      selected: selected,
                      onSelected: (_) {
                        final types = Set<LibraryItemType>.of(state.filterTypes);
                        if (selected) {
                          types.remove(type);
                        } else {
                          types.add(type);
                        }
                        // Include all current filter values so scalar fields
                        // are not accidentally cleared.
                        context.read<LibraryBloc>().add(FilterBy(
                              tagIds: state.filterTagIds,
                              types: types,
                              colorLabel: state.filterColorLabel,
                              isFavorite: state.filterIsFavorite,
                            ));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Tags',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: state.tags.map((tag) {
                    final selected = state.filterTagIds.contains(tag.id);
                    return ChoiceChip(
                      avatar: CircleAvatar(
                          backgroundColor: tag.color, radius: 6),
                      label: Text(tag.name),
                      selected: selected,
                      onSelected: (_) {
                        final ids = Set<String>.of(state.filterTagIds);
                        if (selected) {
                          ids.remove(tag.id);
                        } else {
                          ids.add(tag.id);
                        }
                        context.read<LibraryBloc>().add(FilterBy(
                              tagIds: ids,
                              types: state.filterTypes,
                              colorLabel: state.filterColorLabel,
                              isFavorite: state.filterIsFavorite,
                            ));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Options',
                    style: Theme.of(context).textTheme.labelLarge),
                CheckboxListTile(
                  title: const Text('Favorites only'),
                  value: state.filterIsFavorite == true,
                  onChanged: (v) => context.read<LibraryBloc>().add(
                        FilterBy(
                          tagIds: state.filterTagIds,
                          types: state.filterTypes,
                          colorLabel: state.filterColorLabel,
                          isFavorite: v == true ? true : null,
                        ),
                      ),
                  dense: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _typeName(LibraryItemType type) {
    switch (type) {
      case LibraryItemType.notebook:
        return 'Notebooks';
      case LibraryItemType.infiniteCanvas:
        return 'Canvases';
      case LibraryItemType.folder:
        return 'Folders';
    }
  }
}
