import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:y2notes2/app/app.dart';
import 'package:y2notes2/core/engine/haptic_controller.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/documents/data/document_repository.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.init();

  final prefs = await SharedPreferences.getInstance();
  final documentRepository = DocumentRepository(prefs);

  // Register all plugin-based drawing tools.
  ToolRegistry.registerAll();

  // Bind haptic controller to settings
  HapticController.bind(settingsService);

  runApp(
    ServiceProvider<SettingsService>(
      service: settingsService,
      child: ServiceProvider<DocumentRepository>(
        service: documentRepository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => CanvasBloc(settingsService: settingsService),
            ),
          ],
          child: Y2NotesApp(settingsService: settingsService),
        ),
      ),
    ),
  );
}
