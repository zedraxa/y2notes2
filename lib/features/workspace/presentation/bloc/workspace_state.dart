import 'package:equatable/equatable.dart';
import 'package:biscuits/features/workspace/domain/tab_session.dart';

/// Immutable snapshot of workspace state.
class WorkspaceState extends Equatable {
  const WorkspaceState({
    this.tabs = const [],
    this.activeTabId = '',
  });

  final List<TabSession> tabs;
  final String activeTabId;

  /// Index of the currently active tab, or -1 if not found.
  int get activeTabIndex =>
      tabs.indexWhere((t) => t.id == activeTabId);

  /// The currently active tab, or null.
  TabSession? get activeTab =>
      tabs.isEmpty ? null : tabs.firstWhere(
        (t) => t.id == activeTabId,
        orElse: () => tabs.first,
      );

  WorkspaceState copyWith({
    List<TabSession>? tabs,
    String? activeTabId,
  }) =>
      WorkspaceState(
        tabs: tabs ?? this.tabs,
        activeTabId: activeTabId ?? this.activeTabId,
      );

  @override
  List<Object?> get props => [tabs, activeTabId];
}
