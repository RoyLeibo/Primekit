import 'dart:async';

import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Global crash-reporting configuration for a Primekit application.
///
/// Call [initialize] once at app startup — typically inside `main()` or
/// inside a `runZonedGuarded` block — to wire up all error hooks.
///
/// ```dart
/// void main() {
///   runZonedGuarded(() async {
///     WidgetsFlutterBinding.ensureInitialized();
///
///     await CrashConfig.initialize(
///       FirebaseCrashReporter(),
///       captureFlutterErrors: true,
///       capturePlatformErrors: true,
///     );
///
///     runApp(const MyApp());
///   }, (error, stack) async {
///     await CrashConfig.recordError(error, stack, fatal: true);
///   });
/// }
/// ```
abstract final class CrashConfig {
  /// Registers [reporter] and installs the requested error hooks.
  static Future<void> initialize(
    CrashReporter reporter, {
    bool captureFlutterErrors = true,
    bool capturePlatformErrors = true,
    bool captureUnhandledAsync = true,
    bool enabled = true,
  }) async {
    _reporter = reporter;
    reporter.setEnabled(enabled: enabled);
    await reporter.initialize();

    if (captureFlutterErrors) {
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) async {
        previousHandler?.call(details);
        await reporter.recordError(
          details.exception,
          details.stack,
          reason: details.exceptionAsString(),
        );
      };
    }

    if (capturePlatformErrors) {
      PlatformDispatcher.instance.onError = (error, stack) {
        reporter.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  /// The active [CrashReporter], or `null` if [initialize] has not been called.
  static CrashReporter? get reporter => _reporter;

  /// Adds [breadcrumb] to the active reporter (no-op if not initialised).
  static void addBreadcrumb(Breadcrumb breadcrumb) {
    _reporter?.addBreadcrumb(breadcrumb);
  }

  /// Records [error] via the active reporter (no-op if not initialised).
  static Future<void> recordError(
    Object error,
    StackTrace? st, {
    bool fatal = false,
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    await _reporter?.recordError(
      error,
      st,
      fatal: fatal,
      reason: reason,
      context: context,
    );
  }

  static CrashReporter? _reporter;
}
