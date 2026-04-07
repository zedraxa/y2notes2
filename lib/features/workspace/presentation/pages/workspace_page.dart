import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/canvas_view.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/toolbar/main_toolbar.dart';
import 'package:y2notes2/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:y2notes2/features/workspace/presentation/bloc/workspace_event.dart';
import 'package:y2notes2/features/workspace/presentation/bloc/workspace_state.dart';
import 'package:y2notes2/features/workspace/presentation/widgets/tab_bar_widget.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Root workspace shell that hosts browser-like tabs.
///
/// Each tab gets its own independent [CanvasBloc]. Switching tabs preserves
/// every tab's canvas state independently.
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  /// One [CanvasBloc] per tab, keyed by tab ID.
  final Map<String, CanvasBloc> _canvasBlocs = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Eagerly create CanvasBlocs for any tabs already present when the page
    // first mounts (the BlocConsumer listener won't fire for the initial state).
    final settings = ServiceProvider.of<SettingsService>(context);
    final wsState = context.read<WorkspaceBloc>().state;
    for (final tab in wsState.tabs) {
      _ensureBloc(tab.id, settings);
    }
  }

  @override
  void dispose() {
    for (final bloc in _canvasBlocs.values) {
      bloc.close();
    }
    super.dispose();
  }

  // ── CanvasBloc lifecycle helpers ─────────────────────────────────────────

  void _ensureBloc(String tabId, SettingsService settings) {
    if (!_canvasBlocs.containsKey(tabId)) {
      _canvasBlocs[tabId] = CanvasBloc(settingsService: settings);
    }
  }

  void _removeBloc(String tabId) {
    _canvasBlocs[tabId]?.close();
    _canvasBlocs.remove(tabId);
  }

  // ── Keyboard shortcut handler ────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (!isMetaOrCtrl) return KeyEventResult.ignored;

    final bloc = context.read<WorkspaceBloc>();

    // Cmd/Ctrl + T → new tab
    if (event.logicalKey == LogicalKeyboardKey.keyT) {
      bloc.add(const TabOpened());
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl + W → close active tab
    if (event.logicalKey == LogicalKeyboardKey.keyW) {
      bloc.add(const ActiveTabClosed());
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl + 1-8 → switch to tab by 1-based index
    final digitMap = {
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
      LogicalKeyboardKey.digit5: 4,
      LogicalKeyboardKey.digit6: 5,
      LogicalKeyboardKey.digit7: 6,
      LogicalKeyboardKey.digit8: 7,
    };
    final index = digitMap[event.logicalKey];
    if (index != null) {
      bloc.add(TabSwitchedByIndex(index));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: BlocConsumer<WorkspaceBloc, WorkspaceState>(
          listener: (context, state) {
            // Ensure a CanvasBloc exists for every tab.
            for (final tab in state.tabs) {
              _ensureBloc(tab.id, settings);
            }
            // Dispose blocs for tabs that no longer exist.
            final liveIds = state.tabs.map((t) => t.id).toSet();
            _canvasBlocs.keys
                .toList()
                .where((id) => !liveIds.contains(id))
                .forEach(_removeBloc);
          },
          builder: (context, state) {
            final activeBloc = _canvasBlocs[state.activeTabId];
            final workspaceBloc = context.read<WorkspaceBloc>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // System status bar safe area
                SizedBox(height: MediaQuery.of(context).padding.top),
                // ── Tab bar ─────────────────────────────────────────────────
                TabBarWidget(
                  state: state,
                  onNewTab: () => workspaceBloc.add(const TabOpened()),
                  onCloseTab: (id) => workspaceBloc.add(TabClosed(id)),
                  onSwitchTab: (id) => workspaceBloc.add(TabSwitched(id)),
                  onReorderTabs: (tabs) =>
                      workspaceBloc.add(TabsReordered(tabs)),
                  onRenameTab: (id, title) =>
                      workspaceBloc.add(TabRenamed(tabId: id, newTitle: title)),
                  onPinTab: (id) => workspaceBloc.add(TabPinned(id)),
                  onDuplicateTab: (id) =>
                      workspaceBloc.add(TabDuplicated(id)),
                ),
                // ── Active canvas (toolbar + drawing surface) ────────────────
                if (activeBloc != null)
                  Expanded(
                    child: BlocProvider<CanvasBloc>.value(
                      value: activeBloc,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MainToolbar(
                            onSettingsTap: () => context.push('/settings'),
                          ),
                          const Expanded(child: CanvasView()),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
