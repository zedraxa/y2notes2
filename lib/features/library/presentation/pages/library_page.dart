import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:biscuits/app/route_names.dart';
import 'package:biscuits/features/library/domain/entities/folder.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';
import 'package:biscuits/features/library/presentation/widgets/folder_breadcrumbs.dart';
import 'package:biscuits/features/library/presentation/widgets/library_grid.dart';
import 'package:biscuits/features/library/presentation/widgets/library_list.dart';
import 'package:biscuits/features/library/presentation/widgets/smart_collection_card.dart';
import 'package:biscuits/features/library/presentation/widgets/sort_filter_bar.dart';
import 'package:biscuits/features/library/presentation/widgets/spotlight_search.dart';
import 'package:biscuits/features/library/presentation/widgets/tag_cloud.dart';
import 'package:biscuits/features/library/presentation/widgets/trash_view.dart';
import 'package:biscuits/features/scanner/domain/entities/scanned_document.dart';
import 'package:biscuits/shared/widgets/apple_toast.dart';
import 'package:biscuits/shared/widgets/apple_sheet.dart';
import 'package:biscuits/shared/widgets/keyboard_shortcuts_overlay.dart';
import 'package:biscuits/shared/widgets/skeleton_loader.dart';

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
    // ⌘+/ → Keyboard shortcuts overlay
    if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.slash) {
      KeyboardShortcutsOverlay.show(context);
      return KeyEventResult.handled;
    }
    // ⌘+, → Settings
    if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.comma) {
      context.push('/settings');
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
          ? Semantics(
              label: 'Search library',
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
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
              ),
            )
          : const Text('Library'),
      actions: [
        if (!state.isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search (⌘K)',
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
          icon: const Icon(Icons.keyboard_rounded),
          tooltip: 'Keyboard Shortcuts (⌘/)',
          onPressed: () => KeyboardShortcutsOverlay.show(context),
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
              'Biscuits',
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
            final isActive = state.activeSmartCollection?.id == col.id;
            return ListTile(
              leading: Text(col.emoji ?? '📂',
                  style: const TextStyle(fontSize: 20)),
              title: Text(col.name),
              trailing: Text('$count',
                  style: Theme.of(context).textTheme.bodySmall),
              selected: isActive,
              dense: true,
              onTap: () {
                Navigator.pop(context);
                context.read<LibraryBloc>().add(
                      FilterBySmartCollection(isActive ? null : col),
                    );
              },
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
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    if (state.isLoading) {
      return const LibraryGridSkeleton();
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    context.read<LibraryBloc>().add(const LoadLibrary()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Breadcrumbs
        if (!state.isSearching && state.activeSmartCollection == null)
          const FolderBreadcrumbs(),
        // Active smart collection banner
        if (state.activeSmartCollection != null)
          _buildActiveCollectionBanner(context, state),
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
        // Smart collections strip (only at root, not searching, no active collection)
        if (!state.isSearching &&
            state.currentFolderId == null &&
            state.activeSmartCollection == null)
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
          final isActive = state.activeSmartCollection?.id == col.id;
          return SizedBox(
            width: 140,
            child: SmartCollectionCard(
              collection: col,
              itemCount: count,
              isActive: isActive,
              onTap: () {
                context.read<LibraryBloc>().add(
                      FilterBySmartCollection(isActive ? null : col),
                    );
              },
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

  Widget _buildActiveCollectionBanner(
      BuildContext context, LibraryState state) {
    final col = state.activeSmartCollection!;
    return ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (col.emoji != null)
              Text(col.emoji!, style: const TextStyle(fontSize: 18))
            else
              Icon(Icons.filter_list,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              col.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Clear filter',
              onPressed: () => context
                  .read<LibraryBloc>()
                  .add(const FilterBySmartCollection(null)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateMenu(BuildContext context) {
    showAppleActionSheet<void>(
      context: context,
      title: 'Create New',
      actions: [
        AppleActionSheetAction(
          label: 'New Notebook',
          icon: Icons.menu_book_outlined,
          onPressed: () =>
              _showCreateItemDialog(context, LibraryItemType.notebook),
        ),
        AppleActionSheetAction(
          label: 'New Canvas',
          icon: Icons.dashboard_outlined,
          onPressed: () =>
              _showCreateItemDialog(context, LibraryItemType.infiniteCanvas),
        ),
        AppleActionSheetAction(
          label: 'New Folder',
          icon: Icons.create_new_folder_outlined,
          onPressed: () => _showCreateFolderDialog(context),
        ),
        AppleActionSheetAction(
          label: 'Import Document',
          icon: Icons.file_open_outlined,
          onPressed: () => _importDocument(context),
        ),
        AppleActionSheetAction(
          label: 'Flash Cards',
          icon: Icons.style_outlined,
          onPressed: () => context.push(AppRoutes.flashcards),
        ),
        AppleActionSheetAction(
          label: 'Scan Document',
          icon: Icons.document_scanner_outlined,
          onPressed: () => _scanDocument(context),
        ),
      ],
      cancelAction: const AppleActionSheetAction(label: 'Cancel'),
    );
  }

  void _showCreateItemDialog(BuildContext context, LibraryItemType type) {
    final typeName =
        type == LibraryItemType.notebook ? 'Notebook' : 'Canvas';
    final controller = TextEditingController();
    showAppleDialog<void>(
      context: context,
      title: 'New $typeName',
      contentWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Untitled $typeName'),
          autofocus: true,
          onSubmitted: (_) {
            _submitCreateItem(context, controller.text.trim(), type);
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        AppleDialogAction(
          label: 'Cancel',
          onPressed: () {},
        ),
        AppleDialogAction(
          label: 'Create',
          isDefault: true,
          onPressed: () {
            _submitCreateItem(context, controller.text.trim(), type);
          },
        ),
      ],
    ).then((_) => controller.dispose());
  }

  void _submitCreateItem(
      BuildContext context, String name, LibraryItemType type) {
    if (name.isEmpty) return;
    final id = const Uuid().v4();
    context.read<LibraryBloc>().add(CreateItem(id: id, name: name, type: type));
    final typeName =
        type == LibraryItemType.notebook ? 'Notebook' : 'Canvas';
    AppleToast.show(
      context,
      message: '$typeName "$name" created',
      style: AppleToastStyle.success,
    );
    // Navigate to the newly created item.
    if (type == LibraryItemType.notebook) {
      context.push(AppRoutes.notebook(id));
    } else if (type == LibraryItemType.infiniteCanvas) {
      context.push(AppRoutes.infiniteCanvas(id));
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showAppleDialog<void>(
      context: context,
      title: 'New Folder',
      contentWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
          onSubmitted: (_) {
            _submitCreateFolder(context, controller.text.trim());
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        AppleDialogAction(
          label: 'Cancel',
          onPressed: () {},
        ),
        AppleDialogAction(
          label: 'Create',
          isDefault: true,
          onPressed: () {
            _submitCreateFolder(context, controller.text.trim());
          },
        ),
      ],
    ).then((_) => controller.dispose());
  }

  void _submitCreateFolder(BuildContext context, String name) {
    if (name.isEmpty) return;
    context.read<LibraryBloc>().add(CreateFolder(name: name));
    AppleToast.show(
      context,
      message: 'Folder "$name" created',
      style: AppleToastStyle.success,
    );
  }

  Future<void> _scanDocument(BuildContext context) async {
    final result = await context.push<ScanResult>(AppRoutes.scanner);
    if (result != null && result.hasPages && context.mounted) {
      final id = const Uuid().v4();
      final title = result.title ?? 'Scanned Document';
      context.read<LibraryBloc>().add(
            CreateItem(id: id, name: title, type: LibraryItemType.notebook),
          );
      AppleToast.show(
        context,
        message: '"$title" saved (${result.pageCount} pages)',
        style: AppleToastStyle.success,
      );
      context.push(AppRoutes.notebook(id));
    }
  }

  Future<void> _importDocument(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      if (!context.mounted) return;
      final fileName =
          file.name.replaceAll(RegExp(r'\.(pdf|png|jpe?g)$', caseSensitive: false), '');
      final id = const Uuid().v4();
      context.read<LibraryBloc>().add(
            CreateItem(id: id, name: fileName, type: LibraryItemType.notebook),
          );
      AppleToast.show(
        context,
        message: '"$fileName" imported',
        style: AppleToastStyle.success,
      );
      context.push(AppRoutes.notebook(id));
    } catch (e) {
      if (context.mounted) {
        AppleToast.show(
          context,
          message: 'Failed to import document',
          style: AppleToastStyle.error,
        );
      }
    }
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
