import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuitse/features/workspace/domain/tab_session.dart';
import 'package:biscuitse/features/workspace/presentation/bloc/workspace_event.dart';
import 'package:biscuitse/features/workspace/presentation/bloc/workspace_state.dart';

/// Maximum number of tabs allowed at once.
const int kMaxTabs = 8;

/// BLoC that manages the multi-tab workspace state.
class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc() : super(_initialState()) {
    on<TabOpened>(_onTabOpened);
    on<TabClosed>(_onTabClosed);
    on<ActiveTabClosed>(_onActiveTabClosed);
    on<TabSwitched>(_onTabSwitched);
    on<TabSwitchedByIndex>(_onTabSwitchedByIndex);
    on<TabsReordered>(_onTabsReordered);
    on<TabRenamed>(_onTabRenamed);
    on<TabPinned>(_onTabPinned);
    on<TabDuplicated>(_onTabDuplicated);
  }

  final _uuid = const Uuid();

  static WorkspaceState _initialState() {
    const uuid = Uuid();
    final firstId = uuid.v4();
    return WorkspaceState(
      tabs: [
        TabSession(
          id: firstId,
          title: 'Untitled',
          createdAt: DateTime.now(),
        ),
      ],
      activeTabId: firstId,
    );
  }

  void _onTabOpened(TabOpened event, Emitter<WorkspaceState> emit) {
    if (state.tabs.length >= kMaxTabs) return;
    final id = _uuid.v4();
    final newTab = TabSession(
      id: id,
      title: event.title,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(
      tabs: [...state.tabs, newTab],
      activeTabId: id,
    ));
  }

  void _onTabClosed(TabClosed event, Emitter<WorkspaceState> emit) {
    final tabs = List<TabSession>.of(state.tabs);
    final closedIndex = tabs.indexWhere((t) => t.id == event.tabId);
    if (closedIndex < 0) return;

    // Don't close pinned tabs unless it's the only tab.
    final tab = tabs[closedIndex];
    if (tab.isPinned && tabs.length > 1) return;

    tabs.removeAt(closedIndex);

    // If no tabs remain, create a fresh one.
    if (tabs.isEmpty) {
      final newId = _uuid.v4();
      tabs.add(TabSession(id: newId, title: 'Untitled', createdAt: DateTime.now()));
      emit(state.copyWith(tabs: tabs, activeTabId: newId));
      return;
    }

    // Determine next active tab.
    String nextActiveId = state.activeTabId;
    if (state.activeTabId == event.tabId) {
      final nextIndex = (closedIndex - 1).clamp(0, tabs.length - 1);
      nextActiveId = tabs[nextIndex].id;
    }
    emit(state.copyWith(tabs: tabs, activeTabId: nextActiveId));
  }

  void _onActiveTabClosed(ActiveTabClosed event, Emitter<WorkspaceState> emit) {
    add(TabClosed(state.activeTabId));
  }

  void _onTabSwitched(TabSwitched event, Emitter<WorkspaceState> emit) {
    if (!state.tabs.any((t) => t.id == event.tabId)) return;
    emit(state.copyWith(activeTabId: event.tabId));
  }

  void _onTabSwitchedByIndex(
      TabSwitchedByIndex event, Emitter<WorkspaceState> emit) {
    if (event.index < 0 || event.index >= state.tabs.length) return;
    emit(state.copyWith(activeTabId: state.tabs[event.index].id));
  }

  void _onTabsReordered(TabsReordered event, Emitter<WorkspaceState> emit) {
    emit(state.copyWith(tabs: event.tabs));
  }

  void _onTabRenamed(TabRenamed event, Emitter<WorkspaceState> emit) {
    final tabs = state.tabs.map((t) {
      if (t.id == event.tabId) return t.copyWith(title: event.newTitle);
      return t;
    }).toList();
    emit(state.copyWith(tabs: tabs));
  }

  void _onTabPinned(TabPinned event, Emitter<WorkspaceState> emit) {
    final tabs = state.tabs.map((t) {
      if (t.id == event.tabId) return t.copyWith(isPinned: !t.isPinned);
      return t;
    }).toList();
    emit(state.copyWith(tabs: tabs));
  }

  void _onTabDuplicated(TabDuplicated event, Emitter<WorkspaceState> emit) {
    if (state.tabs.length >= kMaxTabs) return;
    final source = state.tabs.firstWhere((t) => t.id == event.tabId,
        orElse: () => state.tabs.first);
    final newId = _uuid.v4();
    final duplicate = TabSession(
      id: newId,
      title: '${source.title} (copy)',
      createdAt: DateTime.now(),
    );
    final sourceIndex = state.tabs.indexOf(source);
    final tabs = List<TabSession>.of(state.tabs)
      ..insert(sourceIndex + 1, duplicate);
    emit(state.copyWith(tabs: tabs, activeTabId: newId));
  }
}
