/// Barrel file for the core architecture layer.
///
/// Import this single file to access the service locator, result type,
/// logger, and all sub-settings services.
library;

export 'package:biscuits/core/di/service_locator.dart';
export 'package:biscuits/core/di/dependencies.dart';
export 'package:biscuits/core/utils/result.dart';
export 'package:biscuits/core/services/app_logger.dart';
export 'package:biscuits/core/services/settings_service.dart';
export 'package:biscuits/core/services/settings/theme_settings.dart';
export 'package:biscuits/core/services/settings/effects_settings.dart';
export 'package:biscuits/core/services/settings/stylus_settings.dart';
export 'package:biscuits/core/services/settings/recognition_settings.dart';
export 'package:biscuits/core/services/settings/canvas_settings.dart';
export 'package:biscuits/core/services/settings/backup_settings.dart';
export 'package:biscuits/core/services/settings/tool_settings.dart';
export 'package:biscuits/core/services/storage_service.dart';
