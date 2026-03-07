import 'package:flutter/foundation.dart';
import 'primekit_config.dart';

/// Internal structured logger used across all Primekit modules.
///
/// Respects the [PrimekitLogLevel] set during initialization and is
/// automatically silenced in production builds unless explicitly enabled.
abstract final class PrimekitLogger {
  static PrimekitLogLevel _level = PrimekitLogLevel.warning;

  /// Configures the active log level.
  static void configure(PrimekitLogLevel level) => _level = level;

  /// Logs a verbose message (lowest severity).
  static void verbose(String message, {String? tag}) =>
      _log(PrimekitLogLevel.verbose, message, tag: tag);

  /// Logs a debug message.
  static void debug(String message, {String? tag}) =>
      _log(PrimekitLogLevel.debug, message, tag: tag);

  /// Logs an informational message.
  static void info(String message, {String? tag}) =>
      _log(PrimekitLogLevel.info, message, tag: tag);

  /// Logs a warning.
  static void warning(String message, {String? tag, Object? error}) =>
      _log(PrimekitLogLevel.warning, message, tag: tag, error: error);

  /// Logs an error.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    PrimekitLogLevel.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  static void _log(
    PrimekitLogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _level.index) return;
    if (!kDebugMode && level.index < PrimekitLogLevel.error.index) return;

    final prefix = '[Primekit${tag != null ? ':$tag' : ''}]';
    final icon = switch (level) {
      PrimekitLogLevel.verbose => '🔍',
      PrimekitLogLevel.debug => '🐛',
      PrimekitLogLevel.info => 'ℹ️ ',
      PrimekitLogLevel.warning => '⚠️ ',
      PrimekitLogLevel.error => '🔴',
      PrimekitLogLevel.none => '',
    };

    // ignore: avoid_print — intentional debug output
    print('$icon $prefix $message');
    // ignore: avoid_print
    if (error != null) print('   Error: $error');
    // ignore: avoid_print
    if (stackTrace != null) print('   StackTrace: $stackTrace');
  }
}
