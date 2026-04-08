import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biscuits/app/app.dart';
import 'package:biscuits/core/engine/haptic_controller.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/features/audio_sync/presentation/bloc/audio_sync_bloc.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_preset.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:biscuits/features/cloud_sync/presentation/bloc/cloud_sync_bloc.dart';
import 'package:biscuits/features/collaboration/presentation/bloc/collaboration_bloc.dart';
import 'package:biscuits/features/documents/data/document_repository.dart';
import 'package:biscuits/features/flashcards/data/flash_card_repository.dart';
import 'package:biscuits/features/flashcards/presentation/bloc/flash_card_bloc.dart';
import 'package:biscuits/features/flashcards/presentation/bloc/flash_card_event.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:biscuits/features/infinite_canvas/presentation/bloc/infinite_canvas_bloc.dart';
import 'package:biscuits/features/math_graph/presentation/bloc/graph_bloc.dart';
import 'package:biscuits/features/library/data/library_repository.dart';
import 'package:biscuits/features/media/presentation/bloc/media_bloc.dart';
import 'package:biscuits/features/rich_text/presentation/bloc/rich_text_bloc.dart';
import 'package:biscuits/features/shapes/presentation/bloc/shape_bloc.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuits/features/templates/data/template_repository.dart';
import 'package:biscuits/features/templates/presentation/bloc/template_bloc.dart';
import 'package:biscuits/features/templates/presentation/bloc/template_event.dart';
import 'package:biscuits/features/widgets/presentation/bloc/widget_bloc.dart';
import 'package:biscuits/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:biscuits/shared/widgets/service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.init();

  final prefs = await SharedPreferences.getInstance();
  final documentRepository = DocumentRepository(prefs);
  final libraryRepository = LibraryRepository(prefs);
  final templateRepository = TemplateRepository(prefs);
  final flashCardRepository = FlashCardRepository(prefs);

  // Register all plugin-based drawing tools.
  ToolRegistry.registerAll();

  // Bind haptic controller to settings
  HapticController.bind(settingsService);

  // Bind tool preset persistence to settings
  ToolPresetManager.bind(settingsService);

  runApp(
    ServiceProvider<SettingsService>(
      service: settingsService,
      child: ServiceProvider<DocumentRepository>(
        service: documentRepository,
        child: MultiBlocProvider(
          providers: [
            // WorkspaceBloc manages the tab bar.
            BlocProvider(create: (_) => WorkspaceBloc()),
            // A root CanvasBloc is still provided for the initial tab;
            // WorkspacePage creates per-tab blocs internally.
            BlocProvider(
              create: (_) => CanvasBloc(settingsService: settingsService),
            ),
            BlocProvider(
              create: (ctx) => ShapeBloc(
                canvasBloc: ctx.read<CanvasBloc>(),
              ),
            ),
            BlocProvider(
              create: (_) => StickerBloc(),
            ),
            // HandwritingBloc manages recognition state across the app.
            BlocProvider(create: (_) => HandwritingBloc()),
            // CollaborationBloc manages real-time sync and presence.
            BlocProvider(
              create: (_) => CollaborationBloc(
                // Use placeholder IDs — in a real app these come from auth.
                localUserId: 'local_user',
                localDisplayName: 'Me',
              ),
            ),
            // Template & Widget blocs.
            BlocProvider(
              create: (_) => TemplateBloc(repository: templateRepository)
                ..add(const TemplatesLoaded()),
            ),
            BlocProvider(
              create: (_) => WidgetBloc(),
            ),
            // AudioSyncBloc manages synchronised recording
            // and playback with stroke timestamps.
            BlocProvider(
              create: (_) => AudioSyncBloc(),
            ),
            // Root InfiniteCanvasBloc — individual pages can override with
            // their own scoped provider when needed.
            BlocProvider(
              create: (_) => InfiniteCanvasBloc(),
            ),
            // MediaBloc manages audio/video elements and playback.
            BlocProvider(
              create: (_) => MediaBloc(),
            ),
            // GraphBloc manages interactive math graphs.
            BlocProvider(
              create: (_) => GraphBloc(),
            ),
            // RichTextBloc manages rich text elements on the canvas.
            BlocProvider(
              create: (_) => RichTextBloc(),
            ),
            // CloudSyncBloc manages cloud provider connections and syncing.
            BlocProvider(
              create: (_) => CloudSyncBloc(),
            ),
            // FlashCardBloc manages flash card decks, study sessions, and quizzes.
            BlocProvider(
              create: (_) => FlashCardBloc(repository: flashCardRepository)
                ..add(const FlashCardsLoaded()),
            ),
          ],
          child: BiscuitsApp(
            settingsService: settingsService,
            documentRepository: documentRepository,
            libraryRepository: libraryRepository,
          ),
        ),
      ),
    ),
  );
}
