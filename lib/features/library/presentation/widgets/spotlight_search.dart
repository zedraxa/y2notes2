import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/search_result.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/bloc/library_state.dart';

/// Spotlight-style quick search overlay, triggered by Cmd+K / Ctrl+K.
///
/// Displays a floating command-palette with categorised results that can be
/// navigated by keyboard (↑ / ↓ / Enter / Escape).
class SpotlightSearch extends StatefulWidget {
  const SpotlightSearch({super.key});

  /// Wrap a widget tree so the Cmd+K shortcut opens the Spotlight overlay.
  static Widget shortcutWrapper({
    required Widget child,
    required BuildContext blocContext,
  }) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            blocContext.read<LibraryBloc>().add(const OpenSpotlight()),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            blocContext.read<LibraryBloc>().add(const OpenSpotlight()),
      },
      child: child,
    );
  }

  @override
  State<SpotlightSearch> createState() => _SpotlightSearchState();
}

class _SpotlightSearchState extends State<SpotlightSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      context.read<LibraryBloc>().add(SearchLibrary(q));
    } else {
      context.read<LibraryBloc>().add(const ClearSearch());
    }
    setState(() => _selectedIndex = 0);
  }

  void _close() {
    context.read<LibraryBloc>()
      ..add(const CloseSpotlight())
      ..add(const ClearSearch());
  }

  List<_SpotlightEntry> _buildEntries(LibraryState state) {
    final entries = <_SpotlightEntry>[];

    if (state.searchQuery.isEmpty) {
      // Default: recent items + quick actions
      final recent = state.items
          .where((i) =>
              !i.isInTrash &&
              DateTime.now().difference(i.updatedAt).inDays <= 7)
          .take(5);
      for (final item in recent) {
        entries.add(_SpotlightEntry.item(item));
      }
    } else {
      for (final result in state.searchResults.take(12)) {
        entries.add(_SpotlightEntry.result(result));
      }
    }

    // Quick actions always shown at the bottom.
    entries.addAll([
      _SpotlightEntry.action(
        label: 'New Notebook',
        icon: Icons.menu_book_outlined,
        onActivate: () {
          _close();
          _promptCreate(LibraryItemType.notebook);
        },
      ),
      _SpotlightEntry.action(
        label: 'New Canvas',
        icon: Icons.dashboard_outlined,
        onActivate: () {
          _close();
          _promptCreate(LibraryItemType.infiniteCanvas);
        },
      ),
    ]);

    return entries;
  }

  void _promptCreate(LibraryItemType type) {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateItemDialog(type: type),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final entries = _buildEntries(context.read<LibraryBloc>().state);

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() =>
          _selectedIndex = (_selectedIndex + 1).clamp(0, entries.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() =>
          _selectedIndex = (_selectedIndex - 1).clamp(0, entries.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex < entries.length) {
        entries[_selectedIndex].activate();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
              child: Card(
                elevation: 24,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    // Search field
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Focus(
                        onKeyEvent: _onKey,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search or type a command…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _controller.clear();
                                      context
                                          .read<LibraryBloc>()
                                          .add(const ClearSearch());
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                          onSubmitted: (_) {
                            final state =
                                context.read<LibraryBloc>().state;
                            final entries = _buildEntries(state);
                            if (_selectedIndex < entries.length) {
                              entries[_selectedIndex].activate();
                            }
                          },
                        ),
                      ),
                    ),
                    // Results list
                    Expanded(
                      child: BlocBuilder<LibraryBloc, LibraryState>(
                        builder: (context, state) {
                          final entries = _buildEntries(state);
                          if (entries.isEmpty) {
                            return const Center(
                              child: Text('No results'),
                            );
                          }
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final isSelected = index == _selectedIndex;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(30),
                                leading: Icon(entry.icon),
                                title: Text(entry.label),
                                subtitle: entry.subtitle != null
                                    ? Text(entry.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)
                                    : null,
                                onTap: () {
                                  setState(() => _selectedIndex = index);
                                  entry.activate();
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Keyboard hint
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _KeyHint(label: '↑↓', tooltip: 'Navigate'),
                          const SizedBox(width: 8),
                          _KeyHint(label: '↵', tooltip: 'Open'),
                          const SizedBox(width: 8),
                          _KeyHint(label: 'Esc', tooltip: 'Dismiss'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting types ──────────────────────────────────────────────────────────

class _SpotlightEntry {
  _SpotlightEntry({
    required this.label,
    required this.icon,
    this.subtitle,
    required this.activate,
  });

  factory _SpotlightEntry.item(LibraryItem item) => _SpotlightEntry(
        label: item.name,
        icon: _iconFor(item.type),
        activate: () {/* TODO: navigate to item */},
      );

  factory _SpotlightEntry.result(SearchResult result) => _SpotlightEntry(
        label: result.item.name,
        icon: _iconFor(result.item.type),
        subtitle: result.previewSnippet.isNotEmpty ? result.previewSnippet : null,
        activate: () {/* TODO: navigate to item */},
      );

  factory _SpotlightEntry.action({
    required String label,
    required IconData icon,
    required VoidCallback onActivate,
  }) =>
      _SpotlightEntry(label: label, icon: icon, activate: onActivate);

  final String label;
  final IconData icon;
  final String? subtitle;
  final VoidCallback activate;

  static IconData _iconFor(LibraryItemType type) {
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

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label, required this.tooltip});
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        const SizedBox(width: 4),
        Text(tooltip,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── Quick-create dialog ───────────────────────────────────────────────────────

class _CreateItemDialog extends StatefulWidget {
  const _CreateItemDialog({required this.type});
  final LibraryItemType type;

  @override
  State<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<_CreateItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeName =
        widget.type == LibraryItemType.notebook ? 'Notebook' : 'Canvas';
    return AlertDialog(
      title: Text('New $typeName'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: 'Untitled $typeName'),
        autofocus: true,
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    context.read<LibraryBloc>().add(
          CreateItem(name: name, type: widget.type),
        );
    Navigator.pop(context);
  }
}
