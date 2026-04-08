import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/features/workspace/domain/tab_session.dart';
import 'package:biscuits/features/workspace/presentation/bloc/workspace_state.dart';

/// A single draggable tab in the tab bar.
class TabItem extends StatelessWidget {
  const TabItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onRename,
    required this.onPin,
    required this.onDuplicate,
    required this.onCloseOthers,
    required this.onCloseToTheRight,
    this.isOnly = false,
    this.isLast = false,
  });

  final TabSession tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(String newTitle) onRename;
  final VoidCallback onPin;
  final VoidCallback onDuplicate;
  final VoidCallback onCloseOthers;
  final VoidCallback onCloseToTheRight;

  /// Whether this is the only tab (disables "Close Others").
  final bool isOnly;

  /// Whether this is the last tab in the list (disables "Close to the Right").
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tab.title,
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: () => _showRenameDialog(context),
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.globalPosition),
        onLongPressEnd: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 180),
          margin: const EdgeInsets.only(top: 4, bottom: 0, right: 2),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.darkSurface : AppColors.surface)
                : (isDark ? AppColors.darkToolbarBg : AppColors.toolbarBg),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: isActive
                ? Border(
                    top: BorderSide(color: AppColors.accent, width: 2),
                    left: BorderSide(
                        color: AppColors.toolbarBorder, width: 0.5),
                    right: BorderSide(
                        color: AppColors.toolbarBorder, width: 0.5),
                  )
                : Border(
                    top: BorderSide(color: Colors.transparent, width: 2),
                    left: BorderSide(
                        color: AppColors.toolbarBorder, width: 0.5),
                    right: BorderSide(
                        color: AppColors.toolbarBorder, width: 0.5),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tab.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.push_pin,
                      size: 10,
                      color: AppColors.accent,
                    ),
                  ),
                if (tab.isModified)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _CloseButton(onClose: onClose, isActive: isActive),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<_ContextAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: _ContextAction.rename,
          child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 18),
            title: Text('Rename'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: _ContextAction.pin,
          child: ListTile(
            leading: Icon(
              tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
            ),
            title: Text(tab.isPinned ? 'Unpin' : 'Pin'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: _ContextAction.duplicate,
          child: ListTile(
            leading: Icon(Icons.copy_outlined, size: 18),
            title: Text('Duplicate'),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _ContextAction.closeOthers,
          enabled: !isOnly,
          child: const ListTile(
            leading: Icon(Icons.tab_unselected, size: 18),
            title: Text('Close Others'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: _ContextAction.closeToTheRight,
          enabled: !isLast,
          child: const ListTile(
            leading: Icon(Icons.chevron_right, size: 18),
            title: Text('Close Tabs to the Right'),
            dense: true,
          ),
        ),
        if (!tab.isPinned) const PopupMenuDivider(),
        if (!tab.isPinned)
          const PopupMenuItem(
            value: _ContextAction.close,
            child: ListTile(
              leading: Icon(Icons.close, size: 18, color: Colors.red),
              title: Text('Close', style: TextStyle(color: Colors.red)),
              dense: true,
            ),
          ),
      ],
    ).then((action) {
      if (action == null) return;
      switch (action) {
        case _ContextAction.rename:
          _showRenameDialog(context);
        case _ContextAction.pin:
          onPin();
        case _ContextAction.duplicate:
          onDuplicate();
        case _ContextAction.closeOthers:
          onCloseOthers();
        case _ContextAction.closeToTheRight:
          onCloseToTheRight();
        case _ContextAction.close:
          onClose();
      }
    });
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: tab.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Tab'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tab name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onRename(value.trim());
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onRename(controller.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

enum _ContextAction {
  rename,
  pin,
  duplicate,
  closeOthers,
  closeToTheRight,
  close,
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onClose, required this.isActive});

  final VoidCallback onClose;
  final bool isActive;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && !_hovered) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: const SizedBox(width: 16, height: 16),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onClose,
        child: AnimatedScale(
          scale: _hovered ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _hovered ? Colors.red.withAlpha(30) : Colors.transparent,
            ),
            child: Icon(
              Icons.close,
              size: 10,
              color: _hovered
                  ? Colors.red
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(153),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable, reorderable tab bar shown above the canvas.
class TabBarWidget extends StatelessWidget {
  const TabBarWidget({
    super.key,
    required this.state,
    required this.onNewTab,
    required this.onCloseTab,
    required this.onSwitchTab,
    required this.onReorderTabs,
    required this.onRenameTab,
    required this.onPinTab,
    required this.onDuplicateTab,
    required this.onCloseOtherTabs,
    required this.onCloseTabsToTheRight,
  });

  final WorkspaceState state;
  final VoidCallback onNewTab;
  final void Function(String tabId) onCloseTab;
  final void Function(String tabId) onSwitchTab;
  final void Function(List<TabSession> reordered) onReorderTabs;
  final void Function(String tabId, String newTitle) onRenameTab;
  final void Function(String tabId) onPinTab;
  final void Function(String tabId) onDuplicateTab;
  final void Function(String tabId) onCloseOtherTabs;
  final void Function(String tabId) onCloseTabsToTheRight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkToolbarBg : AppColors.toolbarBg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.toolbarBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                final tabs = List<TabSession>.of(state.tabs);
                if (newIndex > oldIndex) newIndex--;
                final tab = tabs.removeAt(oldIndex);
                tabs.insert(newIndex, tab);
                onReorderTabs(tabs);
              },
              itemCount: state.tabs.length,
              itemBuilder: (context, index) {
                final tab = state.tabs[index];
                final isActive = tab.id == state.activeTabId;
                return ReorderableDragStartListener(
                  key: ValueKey(tab.id),
                  index: index,
                  child: TabItem(
                    tab: tab,
                    isActive: isActive,
                    isOnly: state.tabs.length == 1,
                    isLast: index == state.tabs.length - 1,
                    onTap: () => onSwitchTab(tab.id),
                    onClose: () => onCloseTab(tab.id),
                    onRename: (title) => onRenameTab(tab.id, title),
                    onPin: () => onPinTab(tab.id),
                    onDuplicate: () => onDuplicateTab(tab.id),
                    onCloseOthers: () => onCloseOtherTabs(tab.id),
                    onCloseToTheRight: () =>
                        onCloseTabsToTheRight(tab.id),
                  ),
                );
              },
            ),
          ),
          // New tab button — disabled at max tab limit
          Tooltip(
            message: state.tabs.length >= 8
                ? 'Maximum 8 tabs'
                : 'New tab (⌘T)',
            child: IconButton(
              icon: const Icon(Icons.add, size: 16),
              onPressed: state.tabs.length < 8 ? onNewTab : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
