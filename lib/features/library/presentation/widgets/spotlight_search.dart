import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/features/library/domain/entities/library_item.dart';
import 'package:y2notes2/features/library/domain/entities/search_result.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_event.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_state.dart';

/// Apple Spotlight-style command palette with frosted overlay, clean search
/// field, and categorised results.
class SpotlightSearch extends StatefulWidget {
  const SpotlightSearch({super.key});

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

class _SpotlightSearchState extends State<SpotlightSearch>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
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

    entries.addAll([
      _SpotlightEntry.action(
        label: 'New Notebook',
        icon: Icons.menu_book_rounded,
        onActivate: () {
          _close();
          _promptCreate(LibraryItemType.notebook);
        },
      ),
      _SpotlightEntry.action(
        label: 'New Canvas',
        icon: Icons.dashboard_rounded,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _close,
        child: Material(
          color: isDark
              ? Colors.black.withOpacity(0.6)
              : Colors.black.withOpacity(0.3),
          child: SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 580, maxHeight: 460),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Focus(
                            onKeyEvent: _onKey,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Search or type a command…',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.textSecondary
                                      .withOpacity(0.6),
                                ),
                                suffixIcon: _controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () {
                                          _controller.clear();
                                          context
                                              .read<LibraryBloc>()
                                              .add(const ClearSearch());
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSystemFill
                                    : AppColors.systemGroupedSecondaryBg,
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
                        // Results
                        Flexible(
                          child: BlocBuilder<LibraryBloc, LibraryState>(
                            builder: (context, state) {
                              final entries = _buildEntries(state);
                              if (entries.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No results',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding:
                                    const EdgeInsets.only(top: 4, bottom: 8),
                                shrinkWrap: true,
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  final isSelected = index == _selectedIndex;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accent.withOpacity(0.1)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12),
                                      leading: Icon(
                                        entry.icon,
                                        size: 20,
                                        color: isSelected
                                            ? AppColors.accent
                                            : AppColors.textSecondary,
                                      ),
                                      title: Text(
                                        entry.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.accent
                                              : null,
                                        ),
                                      ),
                                      subtitle: entry.subtitle != null
                                          ? Text(
                                              entry.subtitle!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            )
                                          : null,
                                      onTap: () {
                                        setState(
                                            () => _selectedIndex = index);
                                        entry.activate();
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        // Keyboard hints
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _KeyHint(label: '↑↓', tooltip: 'Navigate'),
                              const SizedBox(width: 12),
                              _KeyHint(label: '↵', tooltip: 'Open'),
                              const SizedBox(width: 12),
                              _KeyHint(label: 'Esc', tooltip: 'Dismiss'),
                              const Spacer(),
                              Text(
                                '⌘K',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
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
        return Icons.menu_book_rounded;
      case LibraryItemType.infiniteCanvas:
        return Icons.dashboard_rounded;
      case LibraryItemType.folder:
        return Icons.folder_rounded;
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
            color: AppColors.textSecondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          tooltip,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
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
