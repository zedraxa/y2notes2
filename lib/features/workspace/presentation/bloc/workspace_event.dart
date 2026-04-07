import 'package:equatable/equatable.dart';
import 'package:biscuitse/features/workspace/domain/tab_session.dart';

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();
  @override
  List<Object?> get props => [];
}

/// Open a new blank tab.
class TabOpened extends WorkspaceEvent {
  const TabOpened({this.title = 'Untitled'});
  final String title;
  @override
  List<Object?> get props => [title];
}

/// Close the tab with [tabId].
class TabClosed extends WorkspaceEvent {
  const TabClosed(this.tabId);
  final String tabId;
  @override
  List<Object?> get props => [tabId];
}

/// Switch focus to the tab with [tabId].
class TabSwitched extends WorkspaceEvent {
  const TabSwitched(this.tabId);
  final String tabId;
  @override
  List<Object?> get props => [tabId];
}

/// Switch to a tab by its 0-based index.
class TabSwitchedByIndex extends WorkspaceEvent {
  const TabSwitchedByIndex(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

/// Close the currently active tab.
class ActiveTabClosed extends WorkspaceEvent {
  const ActiveTabClosed();
}

/// Reorder the tab list (after drag-and-drop).
class TabsReordered extends WorkspaceEvent {
  const TabsReordered(this.tabs);
  final List<TabSession> tabs;
  @override
  List<Object?> get props => [tabs];
}

/// Rename a tab.
class TabRenamed extends WorkspaceEvent {
  const TabRenamed({required this.tabId, required this.newTitle});
  final String tabId;
  final String newTitle;
  @override
  List<Object?> get props => [tabId, newTitle];
}

/// Toggle pin state of a tab.
class TabPinned extends WorkspaceEvent {
  const TabPinned(this.tabId);
  final String tabId;
  @override
  List<Object?> get props => [tabId];
}

/// Duplicate a tab (same title, fresh canvas).
class TabDuplicated extends WorkspaceEvent {
  const TabDuplicated(this.tabId);
  final String tabId;
  @override
  List<Object?> get props => [tabId];
}
