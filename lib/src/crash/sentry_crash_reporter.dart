// ignore: avoid_relative_lib_imports — cross-package
import 'package:sentry_flutter/sentry_flutter.dart'
    hide Breadcrumb // avoid ambiguity with our own Breadcrumb
    ;
import 'package:sentry_flutter/sentry_flutter.dart' as sentry show Breadcrumb;

import 'crash_reporter.dart';

/// Sentry-backed [CrashReporter].
///
/// If your app already initialises Sentry via `SentryFlutter.init`, simply
/// omit `dsn`. Otherwise the reporter initialises Sentry using `dsn`.
///
/// ```dart
/// final reporter = SentryCrashReporter(dsn: 'https://xxx@sentry.io/123');
/// await reporter.initialize();
/// ```
class SentryCrashReporter implements CrashReporter {
  /// Creates a [SentryCrashReporter].
  SentryCrashReporter({String? dsn}) : _dsn = dsn;

  final String? _dsn;
  bool _enabled = true;

  // ---------------------------------------------------------------------------
  // CrashReporter interface
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    if (_dsn == null) {
      // Assume SentryFlutter.init has already been called by the host app.
      return;
    }
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = _dsn
          ..tracesSampleRate = 1.0;
      },
    );
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    if (!_enabled) {
      return;
    }
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (reason != null) {
          scope.setTag('reason', reason);
        }
        if (fatal) {
          scope.level = SentryLevel.fatal;
        }
        context?.forEach(
          (key, value) => scope.setTag(key, value.toString()),
        );
      },
    );
  }

  @override
  void addBreadcrumb(Breadcrumb breadcrumb) {
    if (!_enabled) {
      return;
    }
    Sentry.addBreadcrumb(
      sentry.Breadcrumb(
        message: breadcrumb.message,
        category: breadcrumb.category ?? breadcrumb.type.name,
        level: _toSentryLevel(breadcrumb.level),
        data: breadcrumb.data,
        timestamp: breadcrumb.timestamp,
        type: _toSentryType(breadcrumb.type),
      ),
    );
  }

  @override
  void setUser({required String id, String? email, String? name}) {
    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: id, email: email, name: name)),
    );
  }

  @override
  void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  @override
  void setCustomKey(String key, Object value) {
    Sentry.configureScope((scope) => scope.setTag(key, value.toString()));
  }

  @override
  Future<void> flush() async {
    // Sentry does not expose a public flush; close-and-reinit is not desired.
    // No-op: the SDK flushes automatically before the process exits.
  }

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled({required bool enabled}) {
    _enabled = enabled;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  SentryLevel _toSentryLevel(BreadcrumbLevel level) => switch (level) {
        BreadcrumbLevel.debug => SentryLevel.debug,
        BreadcrumbLevel.info => SentryLevel.info,
        BreadcrumbLevel.warning => SentryLevel.warning,
        BreadcrumbLevel.error => SentryLevel.error,
        BreadcrumbLevel.fatal => SentryLevel.fatal,
      };

  String _toSentryType(BreadcrumbType type) => switch (type) {
        BreadcrumbType.navigation => 'navigation',
        BreadcrumbType.userAction => 'user',
        BreadcrumbType.network => 'http',
        BreadcrumbType.error => 'error',
        BreadcrumbType.info => 'info',
      };
}
