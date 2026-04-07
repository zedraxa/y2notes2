import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:y2notes2/features/canvas/presentation/pages/canvas_page.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/handwriting/presentation/pages/recognition_settings_page.dart';
import 'package:y2notes2/features/infinite_canvas/presentation/pages/infinite_canvas_page.dart';
import 'package:y2notes2/features/library/presentation/pages/library_page.dart';
import 'package:y2notes2/features/settings/presentation/about_settings_page.dart';
import 'package:y2notes2/features/settings/presentation/canvas_settings_page.dart';
import 'package:y2notes2/features/settings/presentation/effects_settings_page.dart';
import 'package:y2notes2/features/settings/presentation/general_settings_page.dart';
import 'package:y2notes2/features/settings/presentation/settings_home_page.dart';
import 'package:y2notes2/features/settings/presentation/stylus_settings_page.dart';
import 'package:y2notes2/features/workspace/presentation/pages/workspace_page.dart';

/// Application router using GoRouter.
class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // ── Library (new root) ──────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryPage(),
      ),
      // ── Legacy workspace (still accessible) ────────────────────────────
      GoRoute(
        path: '/workspace',
        builder: (context, state) => const WorkspacePage(),
      ),
      // ── Notebook viewer ─────────────────────────────────────────────────
      GoRoute(
        path: '/notebook/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final bloc = context.read<DocumentBloc>();
          if (bloc.state.notebook?.id != id) {
            bloc.add(OpenNotebook(notebookId: id));
          }
          return const CanvasPage();
        },
      ),
      GoRoute(
        path: '/notebook/:id/page/:pageNum',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final pageNum =
              int.tryParse(state.pathParameters['pageNum'] ?? '1') ?? 1;
          // If the correct notebook is already loaded, navigate to the page
          // immediately. Otherwise open the notebook first; the page navigation
          // will occur once the BlocListener in NotebookPageView (or the
          // calling code) reacts to the loaded notebook state.
          final bloc = context.read<DocumentBloc>();
          if (bloc.state.notebook?.id == id) {
            bloc.add(NavigateToPage(pageIndex: pageNum - 1));
          } else {
            bloc.add(OpenNotebook(notebookId: id));
            // NavigateToPage will be dispatched by the caller once the notebook
            // is confirmed loaded, avoiding a race condition.
          }
          return const CanvasPage();
        },
      ),
      // ── Infinite canvas ──────────────────────────────────────────────────
      GoRoute(
        path: '/canvas/infinite/:id',
        builder: (context, state) => InfiniteCanvasPage(
          canvasId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/canvas/:id',
        builder: (context, state) {
          // Canvas navigation is handled by WorkspacePage internally.
          return const WorkspacePage();
        },
      ),
      // ── Settings ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsHomePage(),
        routes: [
          GoRoute(
            path: 'general',
            builder: (context, state) => const GeneralSettingsPage(),
          ),
          GoRoute(
            path: 'canvas',
            builder: (context, state) => const CanvasSettingsPage(),
          ),
          GoRoute(
            path: 'effects',
            builder: (context, state) =>
                const EffectsSettingsPage(showEffectsOnly: true),
          ),
          GoRoute(
            path: 'stylus',
            builder: (context, state) => const StylusSettingsPage(),
          ),
          GoRoute(
            path: 'recognition',
            builder: (context, state) => const RecognitionSettingsPage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutSettingsPage(),
          ),
        ],
      ),
    ],
  );
}
