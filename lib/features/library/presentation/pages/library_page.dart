import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
/// Houses the search bar, smart collections, folder navigation, sort/filter
/// toolbar, and the main item grid/list.
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
                appBar: _buildAppBar(context, state),
                drawer: _buildDrawer(context, state),
                body: _buildBody(context, state),
                floatingActionButton: _buildFab(context, state),
              ),
              // Spotlight overlay
              if (state.isSpotlightOpen) const SpotlightSearch(),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, LibraryState state) {
    return AppBar(
      title: state.isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Search…',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    context.read<LibraryBloc>().add(const ClearSearch());
                  },
                ),
              ),
              onChanged: (q) {
                if (q.isNotEmpty) {
                  context.read<LibraryBloc>().add(SearchLibrary(q));
                } else {
                  context.read<LibraryBloc>().add(const ClearSearch());
                }
              },
            )
          : const Text('Library'),
      actions: [
        if (!state.isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.read<LibraryBloc>().add(SearchLibrary(''));
              _searchFocus.requestFocus();
            },
          ),
        IconButton(
          icon: const Icon(Icons.label_outline),
          tooltip: 'Tag Cloud',
          onPressed: () => setState(() => _showTagCloud = !_showTagCloud),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
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
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context, LibraryState state) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Y2Notes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          // Smart collections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Collections',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          ...state.smartCollections.map((col) {
            final count = state.items
                .where((i) => col.matches(i))
                .length;
            return ListTile(
              leading: Text(col.emoji ?? '📂',
                  style: const TextStyle(fontSize: 20)),
              title: Text(col.name),
              trailing: Text('$count',
                  style: Theme.of(context).textTheme.bodySmall),
              dense: true,
              onTap: () {/* TODO: navigate to collection view */},
            );
          }),
          const Divider(),
          // Folders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Folders',
                    style: Theme.of(context).textTheme.labelLarge),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  onPressed: () => _showCreateFolderDialog(context),
                ),
              ],
            ),
          ),
          ...state.folders
              .where((f) => f.isRoot)
              .map((f) => _FolderTile(folder: f)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {/* navigate to settings */},
          ),
        ],
      ),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<LibraryBloc>().add(const LoadLibrary()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Breadcrumbs
        if (!state.isSearching) const FolderBreadcrumbs(),
        // Tag cloud (toggle)
        if (_showTagCloud)
          Container(
            padding: const EdgeInsets.all(16),
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
        // Smart collections strip (only at root, not searching)
        if (!state.isSearching && state.currentFolderId == null)
          _buildSmartCollectionsStrip(context, state),
        // Sort / filter bar
        const SortFilterBar(),
        // Main content
        Expanded(
          child: state.viewMode == LibraryViewMode.grid
              ? const LibraryGrid()
              : const LibraryList(),
        ),
      ],
    );
  }

  Widget _buildSmartCollectionsStrip(BuildContext context, LibraryState state) {
    if (state.smartCollections.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.smartCollections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final col = state.smartCollections[index];
          final count =
              state.items.where((i) => col.matches(i)).length;
          return SizedBox(
            width: 140,
            child: SmartCollectionCard(
              collection: col,
              itemCount: count,
              onTap: () {/* TODO: filter by collection */},
            ),
          );
        },
      ),
    );
  }

  FloatingActionButton _buildFab(BuildContext context, LibraryState state) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateMenu(context),
      icon: const Icon(Icons.add),
      label: const Text('New'),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('New Notebook'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateItemDialog(context, LibraryItemType.notebook);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('New Canvas'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateItemDialog(context, LibraryItemType.infiniteCanvas);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New Folder'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateFolderDialog(context);
              },
            ),
          ],
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

/// A drawer tile for a [Folder].
class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(folder.emoji ?? '📁',
          style: const TextStyle(fontSize: 20)),
      title: Text(folder.name),
      trailing: Text('${folder.childCount}',
          style: Theme.of(context).textTheme.bodySmall),
      dense: true,
      onTap: () =>
          context.read<LibraryBloc>().add(NavigateToFolder(folder.id)),
    );
  }
}
