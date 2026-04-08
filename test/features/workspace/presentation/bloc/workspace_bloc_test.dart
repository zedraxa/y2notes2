import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:biscuits/features/workspace/presentation/bloc/workspace_event.dart';
import 'package:biscuits/features/workspace/presentation/bloc/workspace_state.dart';

void main() {
  group('WorkspaceBloc', () {
    late WorkspaceBloc bloc;

    setUp(() {
      bloc = WorkspaceBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has one tab', () {
      expect(bloc.state.tabs.length, 1);
      expect(bloc.state.activeTab, isNotNull);
      expect(bloc.state.activeTab!.title, 'Untitled');
    });

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabOpened adds a new tab and activates it',
      build: () => WorkspaceBloc(),
      act: (bloc) => bloc.add(const TabOpened(title: 'My Notes')),
      verify: (bloc) {
        expect(bloc.state.tabs.length, 2);
        expect(bloc.state.activeTab!.title, 'My Notes');
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabClosed removes the tab',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        // Open a second tab, then close the first
        bloc.add(const TabOpened(title: 'Second'));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.length, 2);
        final firstTabId = bloc.state.tabs.first.id;
        bloc.add(TabClosed(firstTabId));
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabSwitched changes active tab',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        bloc.add(const TabOpened(title: 'Second'));
        final firstId = bloc.state.tabs.first.id;
        bloc.add(TabSwitched(firstId));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        // After switching, active tab should be the first one
        expect(bloc.state.tabs.length, 2);
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabRenamed changes tab title',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        final tabId = bloc.state.tabs.first.id;
        bloc.add(TabRenamed(tabId: tabId, newTitle: 'Renamed'));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.first.title, 'Renamed');
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabPinned toggles pin state',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        final tabId = bloc.state.tabs.first.id;
        bloc.add(TabPinned(tabId));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.first.isPinned, true);
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabMarkedModified sets isModified flag',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        final tabId = bloc.state.tabs.first.id;
        bloc.add(TabMarkedModified(tabId));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.first.isModified, true);
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabMarkedSaved clears isModified flag',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        final tabId = bloc.state.tabs.first.id;
        bloc.add(TabMarkedModified(tabId));
        bloc.add(TabMarkedSaved(tabId));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.first.isModified, false);
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'does not exceed max tabs limit',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        // Try to open more than kMaxTabs (8) tabs
        for (var i = 0; i < 10; i++) {
          bloc.add(TabOpened(title: 'Tab $i'));
        }
      },
      verify: (bloc) {
        expect(bloc.state.tabs.length, kMaxTabs);
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'closing last tab creates a new Untitled tab',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        final tabId = bloc.state.tabs.first.id;
        bloc.add(TabClosed(tabId));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.length, 1);
        expect(bloc.state.tabs.first.title, 'Untitled');
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'NextTabActivated wraps to first tab',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        bloc.add(const TabOpened(title: 'Second'));
        bloc.add(const NextTabActivated());
      },
      verify: (bloc) {
        expect(bloc.state.tabs.length, 2);
      },
    );

    blocTest<WorkspaceBloc, WorkspaceState>(
      'TabDuplicated creates copy of tab',
      build: () => WorkspaceBloc(),
      act: (bloc) {
        final tabId = bloc.state.tabs.first.id;
        bloc.add(TabDuplicated(tabId));
      },
      verify: (bloc) {
        expect(bloc.state.tabs.length, 2);
        // Duplicated tab has same title
        expect(
          bloc.state.tabs.last.title,
          bloc.state.tabs.first.title,
        );
      },
    );
  });
}
