import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:y2notes2/features/canvas/presentation/pages/canvas_page.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/settings/presentation/effects_settings_page.dart';

/// Application router using GoRouter.
class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CanvasPage(),
      ),
      GoRoute(
        path: '/notebook/:id/page/:pageNum',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final pageNum =
              int.tryParse(state.pathParameters['pageNum'] ?? '1') ?? 1;
          // Open the notebook first, then navigate to the specified page.
          final bloc = context.read<DocumentBloc>();
          if (bloc.state.notebook?.id != id) {
            bloc.add(OpenNotebook(notebookId: id));
          }
          bloc.add(NavigateToPage(pageIndex: pageNum - 1));
          return const CanvasPage();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const EffectsSettingsPage(),
        routes: [
          GoRoute(
            path: 'effects',
            builder: (context, state) =>
                const EffectsSettingsPage(showEffectsOnly: true),
          ),
        ],
      ),
    ],
  );
}
