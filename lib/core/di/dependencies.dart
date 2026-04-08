import 'package:shared_preferences/shared_preferences.dart';
import 'package:biscuits/core/di/service_locator.dart';
import 'package:biscuits/core/services/app_logger.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/core/services/settings/backup_settings.dart';
import 'package:biscuits/core/services/settings/canvas_settings.dart';
import 'package:biscuits/core/services/settings/effects_settings.dart';
import 'package:biscuits/core/services/settings/recognition_settings.dart';
import 'package:biscuits/core/services/settings/stylus_settings.dart';
import 'package:biscuits/core/services/settings/theme_settings.dart';
import 'package:biscuits/core/services/settings/tool_settings.dart';
import 'package:biscuits/core/services/storage_service.dart';
import 'package:biscuits/features/documents/data/document_repository.dart';
import 'package:biscuits/features/flashcards/data/flash_card_repository.dart';
import 'package:biscuits/features/library/data/library_repository.dart';
import 'package:biscuits/features/templates/data/template_repository.dart';

/// Registers all services, repositories, and sub-services in the
/// global [ServiceLocator].
///
/// Call once during app start-up, before `runApp`.
///
/// ```dart
/// await initDependencies();
/// runApp(const BiscuitsApp());
/// ```
Future<void> initDependencies() async {
  final sl = ServiceLocator.instance;
  final log = AppLogger.instance;

  // ── Platform primitives ──────────────────────────────────────────────────
  log.info('Initialising dependencies…', tag: 'DI');

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ── Storage service (in-memory until Isar is integrated) ────────────────
  final storage = InMemoryStorageService();
  await storage.init();
  sl.registerSingleton<StorageService>(storage);

  // ── Settings (facade + sub-services) ─────────────────────────────────────
  final settings = SettingsService();
  await settings.init();

  sl.registerSingleton<SettingsService>(settings);
  sl.registerSingleton<ThemeSettings>(settings.theme);
  sl.registerSingleton<EffectsSettings>(settings.effects);
  sl.registerSingleton<StylusSettings>(settings.stylus);
  sl.registerSingleton<RecognitionSettings>(settings.recognition);
  sl.registerSingleton<CanvasSettings>(settings.canvas);
  sl.registerSingleton<BackupSettings>(settings.backup);
  sl.registerSingleton<ToolSettings>(settings.tools);

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepository(prefs),
  );
  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepository(prefs),
  );
  sl.registerLazySingleton<TemplateRepository>(
    () => TemplateRepository(prefs),
  );
  sl.registerLazySingleton<FlashCardRepository>(
    () => FlashCardRepository(prefs),
  );

  log.info('Dependencies initialised.', tag: 'DI');
}
