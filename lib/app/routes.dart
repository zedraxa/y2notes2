import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/features/canvas/presentation/pages/canvas_page.dart';
import 'package:biscuits/features/cloud_sync/presentation/pages/cloud_sync_settings_page.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_event.dart';
import 'package:biscuits/features/flashcards/presentation/pages/card_editor_page.dart';
import 'package:biscuits/features/flashcards/presentation/pages/deck_detail_page.dart';
import 'package:biscuits/features/flashcards/presentation/pages/deck_list_page.dart';
import 'package:biscuits/features/flashcards/presentation/pages/quiz_page.dart';
import 'package:biscuits/features/flashcards/presentation/pages/stats_page.dart';
import 'package:biscuits/features/flashcards/presentation/pages/study_session_page.dart';
import 'package:biscuits/features/handwriting/presentation/pages/recognition_settings_page.dart';
import 'package:biscuits/features/infinite_canvas/presentation/pages/infinite_canvas_page.dart';
import 'package:biscuits/features/library/presentation/pages/library_page.dart';
import 'package:biscuits/features/pdf_annotation/presentation/pages/pdf_annotation_page.dart';
import 'package:biscuits/features/rich_text/presentation/bloc/rich_text_bloc.dart';
import 'package:biscuits/features/rich_text/presentation/bloc/rich_text_event.dart';
import 'package:biscuits/features/rich_text/presentation/pages/rich_text_editor_page.dart';
import 'package:biscuits/features/scanner/presentation/pages/document_scanner_page.dart';
import 'package:biscuits/features/settings/presentation/about_page.dart';
import 'package:biscuits/features/settings/presentation/backup_settings_page.dart';
import 'package:biscuits/features/settings/presentation/canvas_settings_page.dart';
import 'package:biscuits/features/settings/presentation/effects_settings_page.dart';
import 'package:biscuits/features/settings/presentation/general_settings_page.dart';
import 'package:biscuits/features/settings/presentation/settings_home_page.dart';
import 'package:biscuits/features/settings/presentation/stylus_settings_page.dart';
import 'package:biscuits/features/math_graph/presentation/pages/graph_editor_page.dart';
import 'package:biscuits/features/workspace/presentation/pages/workspace_page.dart';

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
      // ── Rich text editor ────────────────────────────────────────────────
      GoRoute(
        path: '/richtext/:elementId',
        builder: (context, state) {
          final elementId = state.pathParameters['elementId']!;
          // Ensure the element is selected for editing.
          context.read<RichTextBloc>().add(
                SelectRichTextElement(elementId: elementId),
              );
          return RichTextEditorPage(elementId: elementId);
        },
      ),
      GoRoute(
        path: '/canvas/:id',
        builder: (context, state) {
          // Canvas navigation is handled by WorkspacePage internally.
          return const WorkspacePage();
        },
      ),
      // ── Math Graph editor ────────────────────────────────────────────────
      GoRoute(
        path: '/graph',
        builder: (context, state) => const GraphEditorPage(),
      ),
      // ── PDF annotation viewer ─────────────────────────────────────────────
      GoRoute(
        path: '/pdf/annotate',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PdfAnnotationPage(
            filePath: extra['filePath'] as String? ?? '',
            title: extra['title'] as String?,
            initialPageCount: extra['pageCount'] as int? ?? 1,
          );
        },
      ),
      // ── Document Scanner ──────────────────────────────────────────────────
      GoRoute(
        path: '/scanner',
        builder: (context, state) =>
            const DocumentScannerPage(),
      ),
      // ── Flash Cards ──────────────────────────────────────────────────────
      GoRoute(
        path: '/flashcards',
        builder: (context, state) => const DeckListPage(),
        routes: [
          GoRoute(
            path: 'deck/:deckId',
            builder: (context, state) => DeckDetailPage(
              deckId: state.pathParameters['deckId']!,
            ),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => CardEditorPage(
                  deckId: state.pathParameters['deckId']!,
                ),
              ),
              GoRoute(
                path: 'edit/:cardId',
                builder: (context, state) => CardEditorPage(
                  deckId: state.pathParameters['deckId']!,
                  cardId: state.pathParameters['cardId'],
                ),
              ),
              GoRoute(
                path: 'study',
                builder: (context, state) => StudySessionPage(
                  deckId: state.pathParameters['deckId']!,
                ),
              ),
              GoRoute(
                path: 'quiz',
                builder: (context, state) => QuizPage(
                  deckId: state.pathParameters['deckId']!,
                ),
              ),
              GoRoute(
                path: 'stats',
                builder: (context, state) => StatsPage(
                  deckId: state.pathParameters['deckId']!,
                ),
              ),
            ],
          ),
        ],
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
            path: 'backup',
            builder: (context, state) => const BackupSettingsPage(),
          ),
          GoRoute(
            path: 'cloud-sync',
            builder: (context, state) => const CloudSyncSettingsPage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutPage(),
          ),
        ],
      ),
    ],
  );
}
