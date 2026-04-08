import 'package:flutter/foundation.dart';

/// Severity levels for log entries.
enum LogLevel { debug, info, warning, error }

/// Centralised logging abstraction.
///
/// All feature-level code should use [AppLogger] rather than bare
/// `debugPrint` or `print` calls. In debug mode the default
/// [DebugLogger] writes to the console; in release builds it is
/// silent.  Swap the implementation via [AppLogger.instance] for
/// crash-reporting integrations (e.g. Firebase Crashlytics).
abstract class AppLogger {
  /// The active logger singleton.
  static AppLogger instance = const DebugLogger();

  const AppLogger();

  /// Log a [message] at [level], optionally with an [error] and
  /// [stackTrace].
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  });

  /// Convenience methods.

  void debug(String message, {String? tag}) =>
      log(LogLevel.debug, message, tag: tag);

  void info(String message, {String? tag}) =>
      log(LogLevel.info, message, tag: tag);

  void warning(String message, {Object? error, String? tag}) =>
      log(LogLevel.warning, message, error: error, tag: tag);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      log(
        LogLevel.error,
        message,
        error: error,
        stackTrace: stackTrace,
        tag: tag,
      );
}

/// Default logger that writes to [debugPrint] in debug builds.
class DebugLogger extends AppLogger {
  const DebugLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!kDebugMode) return;
    final prefix = tag != null ? '[$tag] ' : '';
    final label = level.name.toUpperCase().padRight(7);
    debugPrint('$label $prefix$message');
    if (error != null) debugPrint('  ↳ $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
