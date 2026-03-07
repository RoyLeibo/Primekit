import 'crash_reporter.dart';

/// A [CrashReporter] that fans out every call to multiple reporters.
///
/// Use this when you want to send crash data to more than one backend
/// simultaneously (e.g. both Firebase Crashlytics and Sentry):
///
/// ```dart
/// final reporter = MultiCrashReporter([
///   FirebaseCrashReporter(),
///   SentryCrashReporter(dsn: 'https://xxx@sentry.io/123'),
/// ]);
/// await reporter.initialize();
/// ```
class MultiCrashReporter implements CrashReporter {
  /// Creates a [MultiCrashReporter] that delegates to [reporters].
  MultiCrashReporter(List<CrashReporter> reporters)
    : _reporters = List.unmodifiable(reporters);

  final List<CrashReporter> _reporters;

  // ---------------------------------------------------------------------------
  // CrashReporter interface
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() =>
      Future.wait(_reporters.map((r) => r.initialize()));

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) => Future.wait(
    _reporters.map(
      (r) => r.recordError(
        error,
        stackTrace,
        reason: reason,
        context: context,
        fatal: fatal,
      ),
    ),
  );

  @override
  void addBreadcrumb(Breadcrumb breadcrumb) {
    for (final reporter in _reporters) {
      reporter.addBreadcrumb(breadcrumb);
    }
  }

  @override
  void setUser({required String id, String? email, String? name}) {
    for (final reporter in _reporters) {
      reporter.setUser(id: id, email: email, name: name);
    }
  }

  @override
  void clearUser() {
    for (final reporter in _reporters) {
      reporter.clearUser();
    }
  }

  @override
  void setCustomKey(String key, Object value) {
    for (final reporter in _reporters) {
      reporter.setCustomKey(key, value);
    }
  }

  @override
  Future<void> flush() => Future.wait(_reporters.map((r) => r.flush()));

  /// Returns `true` if **all** reporters are enabled.
  @override
  bool get isEnabled => _reporters.every((r) => r.isEnabled);

  @override
  void setEnabled({required bool enabled}) {
    for (final reporter in _reporters) {
      reporter.setEnabled(enabled: enabled);
    }
  }
}
