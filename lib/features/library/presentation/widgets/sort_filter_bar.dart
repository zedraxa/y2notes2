import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/features/library/domain/entities/library_item.dart';
import 'package:y2notes2/features/library/domain/entities/tag.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_event.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_state.dart';

/// Apple-style sort + filter toolbar with clean pill buttons and view toggle.
class SortFilterBar extends StatelessWidget {
  const SortFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              // Sort pill
              _SortPill(current: state.sortOrder),
              const SizedBox(width: 8),
              // Clear filters pill
              if (state.hasActiveFilters)
                _FilterPill(
                  onClear: () =>
                      context.read<LibraryBloc>().add(const ClearFilters()),
                ),
              const Spacer(),
              // View mode toggle
              _ViewToggle(mode: state.viewMode),
            ],
          ),
        );
      },
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({required this.current});

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Text(
              _label(current),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
            ),
          ],
        ),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              'Clear filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mode});

  final LibraryViewMode mode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(
            icon: Icons.grid_view_rounded,
            isActive: mode == LibraryViewMode.grid,
            onTap: () {
              if (mode != LibraryViewMode.grid) {
                context.read<LibraryBloc>().add(const ToggleViewMode());
              }
            },
          ),
          _ToggleItem(
            icon: Icons.view_list_rounded,
            isActive: mode == LibraryViewMode.list,
            onTap: () {
              if (mode != LibraryViewMode.list) {
                context.read<LibraryBloc>().add(const ToggleViewMode());
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Filters',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
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
                        final types =
                            Set<LibraryItemType>.of(state.filterTypes);
                        if (selected) {
                          types.remove(type);
                        } else {
                          types.add(type);
                        }
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
