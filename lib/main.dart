import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:y2notes2/app/app.dart';
import 'package:y2notes2/core/engine/haptic_controller.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_preset.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_bloc.dart';
import 'package:y2notes2/features/documents/data/document_repository.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:y2notes2/features/infinite_canvas/presentation/bloc/infinite_canvas_bloc.dart';
import 'package:y2notes2/features/library/data/library_repository.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_bloc.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:y2notes2/features/templates/data/template_repository.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_bloc.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_event.dart';
import 'package:y2notes2/features/widgets/presentation/bloc/widget_bloc.dart';
import 'package:y2notes2/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.init();

  final prefs = await SharedPreferences.getInstance();
  final documentRepository = DocumentRepository(prefs);
  final libraryRepository = LibraryRepository(prefs);
  final templateRepository = TemplateRepository(prefs);

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
            // Root InfiniteCanvasBloc — individual pages can override with
            // their own scoped provider when needed.
            BlocProvider(
              create: (_) => InfiniteCanvasBloc(),
            ),
          ],
          child: Y2NotesApp(
            settingsService: settingsService,
            documentRepository: documentRepository,
            libraryRepository: libraryRepository,
          ),
        ),
      ),
    ),
  );
}
