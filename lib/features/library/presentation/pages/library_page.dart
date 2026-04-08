import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/features/library/domain/entities/folder.dart';
import 'package:y2notes2/features/library/domain/entities/library_item.dart';
import 'package:y2notes2/features/library/domain/entities/tag.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_event.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_state.dart';
import 'package:y2notes2/features/library/presentation/widgets/folder_breadcrumbs.dart';
import 'package:y2notes2/features/library/presentation/widgets/library_grid.dart';
import 'package:y2notes2/features/library/presentation/widgets/library_list.dart';
import 'package:y2notes2/features/library/presentation/widgets/smart_collection_card.dart';
import 'package:y2notes2/features/library/presentation/widgets/sort_filter_bar.dart';
import 'package:y2notes2/features/library/presentation/widgets/spotlight_search.dart';
import 'package:y2notes2/features/library/presentation/widgets/tag_cloud.dart';
import 'package:y2notes2/features/library/presentation/widgets/trash_view.dart';

/// The root screen of the app — the unified document library.
///
/// Apple-style large-title navigation with embedded search, smart collections
/// strip, and a clean content area.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showTagCloud = false;

  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(const LoadLibrary());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Keyboard shortcuts ────────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      context.read<LibraryBloc>().add(const OpenSpotlight());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            children: [
              Scaffold(
                body: _buildBody(context, state),
                floatingActionButton: _buildFab(context, state),
              ),
              if (state.isSpotlightOpen) const SpotlightSearch(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  context.read<LibraryBloc>().add(const LoadLibrary()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // ── Apple-style large title app bar ──────────────────────────────
        SliverAppBar.large(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.only(left: 20, bottom: 16, right: 20),
            title: Text(
              'Library',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tag_rounded, size: 22),
              tooltip: 'Tags',
              onPressed: () =>
                  setState(() => _showTagCloud = !_showTagCloud),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 22),
              tooltip: 'Trash',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<LibraryBloc>(),
                    child: const TrashView(),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        // ── Search bar ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: GestureDetector(
              onTap: () {
                if (!state.isSearching) {
                  context.read<LibraryBloc>().add(SearchLibrary(''));
                  _searchFocus.requestFocus();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurface
                      : AppColors.systemFill.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: state.isSearching
                    ? Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              style: const TextStyle(fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Search notes, folders…',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                              onChanged: (q) {
                                if (q.isNotEmpty) {
                                  context
                                      .read<LibraryBloc>()
                                      .add(SearchLibrary(q));
                                } else {
                                  context
                                      .read<LibraryBloc>()
                                      .add(const ClearSearch());
                                }
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              context
                                  .read<LibraryBloc>()
                                  .add(const ClearSearch());
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        // ── Breadcrumbs ─────────────────────────────────────────────────
        if (!state.isSearching)
          const SliverToBoxAdapter(child: FolderBreadcrumbs()),
        // ── Tag cloud (toggle) ──────────────────────────────────────────
        if (_showTagCloud)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TagCloud(
                tags: state.tags,
                onTagTap: (tag) {
                  final ids = Set<String>.of(state.filterTagIds);
                  if (ids.contains(tag.id)) {
                    ids.remove(tag.id);
                  } else {
                    ids.add(tag.id);
                  }
                  context.read<LibraryBloc>().add(FilterBy(tagIds: ids));
                },
              ),
            ),
          ),
        // ── Smart collections ───────────────────────────────────────────
        if (!state.isSearching && state.currentFolderId == null)
          SliverToBoxAdapter(
            child: _buildSmartCollectionsStrip(context, state),
          ),
        // ── Sort / filter bar ───────────────────────────────────────────
        const SliverToBoxAdapter(child: SortFilterBar()),
        // ── Main content ────────────────────────────────────────────────
        SliverFillRemaining(
          child: state.viewMode == LibraryViewMode.grid
              ? const LibraryGrid()
              : const LibraryList(),
        ),
      ],
    );
  }

  Widget _buildSmartCollectionsStrip(BuildContext context, LibraryState state) {
    if (state.smartCollections.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: state.smartCollections.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final col = state.smartCollections[index];
            final count =
                state.items.where((i) => col.matches(i)).length;
            return SizedBox(
              width: 150,
              child: SmartCollectionCard(
                collection: col,
                itemCount: count,
                onTap: () {/* TODO: filter by collection */},
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, LibraryState state) {
    return FloatingActionButton(
      onPressed: () => _showCreateMenu(context),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Create New',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 4),
              _CreateMenuItem(
                icon: Icons.menu_book_rounded,
                label: 'Notebook',
                subtitle: 'Pages with handwriting & drawing',
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateItemDialog(context, LibraryItemType.notebook);
                },
              ),
              _CreateMenuItem(
                icon: Icons.dashboard_rounded,
                label: 'Infinite Canvas',
                subtitle: 'Freeform workspace without pages',
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateItemDialog(
                      context, LibraryItemType.infiniteCanvas);
                },
              ),
              _CreateMenuItem(
                icon: Icons.folder_rounded,
                label: 'Folder',
                subtitle: 'Organize your notes',
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateFolderDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateItemDialog(BuildContext context, LibraryItemType type) {
    final typeName =
        type == LibraryItemType.notebook ? 'Notebook' : 'Canvas';
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('New $typeName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Untitled $typeName'),
          autofocus: true,
          onSubmitted: (_) {
            _submitCreateItem(context, controller.text.trim(), type);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _submitCreateItem(context, controller.text.trim(), type);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _submitCreateItem(
      BuildContext context, String name, LibraryItemType type) {
    if (name.isEmpty) return;
    context.read<LibraryBloc>().add(CreateItem(name: name, type: type));
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
          onSubmitted: (_) {
            _submitCreateFolder(context, controller.text.trim());
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _submitCreateFolder(context, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _submitCreateFolder(BuildContext context, String name) {
    if (name.isEmpty) return;
    context.read<LibraryBloc>().add(CreateFolder(name: name));
  }
}

/// Apple-style bottom sheet menu item.
class _CreateMenuItem extends StatelessWidget {
  const _CreateMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accent, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
