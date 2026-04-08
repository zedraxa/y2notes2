import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/features/library/domain/entities/library_item.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_event.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_state.dart';
import 'package:y2notes2/features/library/presentation/widgets/item_context_menu.dart';

/// Displays library items in a responsive grid with Apple-style card design.
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
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    state.isSearching
                        ? Icons.search_off_rounded
                        : Icons.note_add_rounded,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, child) => Opacity(
                    opacity: value,
                    child: child,
                  ),
                  child: Text(
                    state.isSearching ? 'No Results' : 'No Notes Yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.4),
                        ),
                  ),
                ),
                if (!state.isSearching) ...[
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                    child: Text(
                      'Tap + to create your first notebook',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.3),
                          ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorLabel = item.colorLabel?.color;
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
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
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                      ),
                      child: Center(
                        child: Icon(
                          _iconFor(item.type),
                          size: 36,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                    ),
                  // Color label stripe
                  if (colorLabel != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 3, color: colorLabel),
                    ),
                  // Favourite indicator
                  if (item.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.systemYellow,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
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
        return Icons.menu_book_rounded;
      case LibraryItemType.infiniteCanvas:
        return Icons.dashboard_rounded;
      case LibraryItemType.folder:
        return Icons.folder_rounded;
    }
  }
}
