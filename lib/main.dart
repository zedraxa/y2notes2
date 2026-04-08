import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/app/app.dart';
import 'package:biscuits/core/di/dependencies.dart';
import 'package:biscuits/core/di/service_locator.dart';
import 'package:biscuits/core/engine/haptic_controller.dart';
import 'package:biscuits/core/services/app_logger.dart';
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

void main() {
  // Catch Flutter framework errors.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.instance.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FlutterError',
    );
  };

  // Run inside a guarded zone so async errors are captured.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Initialise dependency graph ───────────────────────────────────
      await initDependencies();

      final sl = ServiceLocator.instance;
      final settingsService = sl<SettingsService>();
      final documentRepository = sl<DocumentRepository>();
      final libraryRepository = sl<LibraryRepository>();
      final templateRepository = sl<TemplateRepository>();
      final flashCardRepository = sl<FlashCardRepository>();

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
                BlocProvider(
                  create: (_) => WorkspaceBloc(),
                ),
                BlocProvider(
                  create: (_) => CanvasBloc(
                    settingsService: settingsService,
                  ),
                ),
                BlocProvider(
                  create: (ctx) => ShapeBloc(
                    canvasBloc: ctx.read<CanvasBloc>(),
                  ),
                ),
                BlocProvider(
                  create: (_) => StickerBloc(),
                ),
                BlocProvider(
                  create: (_) => HandwritingBloc(),
                ),
                BlocProvider(
                  create: (_) => CollaborationBloc(
                    localUserId: 'local_user',
                    localDisplayName: 'Me',
                  ),
                ),
                BlocProvider(
                  create: (_) =>
                      TemplateBloc(repository: templateRepository)
                        ..add(const TemplatesLoaded()),
                ),
                BlocProvider(
                  create: (_) => WidgetBloc(),
                ),
                BlocProvider(
                  create: (_) => AudioSyncBloc(),
                ),
                BlocProvider(
                  create: (_) => InfiniteCanvasBloc(),
                ),
                BlocProvider(
                  create: (_) => MediaBloc(),
                ),
                BlocProvider(
                  create: (_) => GraphBloc(),
                ),
                BlocProvider(
                  create: (_) => RichTextBloc(),
                ),
                BlocProvider(
                  create: (_) => CloudSyncBloc(),
                ),
                BlocProvider(
                  create: (_) =>
                      FlashCardBloc(repository: flashCardRepository)
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
    },
    (error, stackTrace) {
      AppLogger.instance.error(
        'Unhandled error',
        error: error,
        stackTrace: stackTrace,
        tag: 'Zone',
      );
    },
  );
}
