import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporter.dart';

/// Firebase Crashlytics-backed [CrashReporter].
///
/// ```dart
/// final reporter = FirebaseCrashReporter();
/// await reporter.initialize();
///
/// FlutterError.onError = (details) async {
///   await reporter.recordError(
///     details.exception,
///     details.stack,
///     fatal: true,
///   );
/// };
/// ```
class FirebaseCrashReporter implements CrashReporter {
  /// Creates a [FirebaseCrashReporter].
  ///
  /// Supply a custom [crashlytics] instance for testing; otherwise
  /// [FirebaseCrashlytics.instance] is used.
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  // ---------------------------------------------------------------------------
  // CrashReporter interface
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(_enabled);
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
    if (context != null) {
      for (final entry in context.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  void addBreadcrumb(Breadcrumb breadcrumb) {
    if (!_enabled) {
      return;
    }
    final parts = [
      '[${breadcrumb.level.name.toUpperCase()}]',
      if (breadcrumb.category != null) '(${breadcrumb.category})',
      breadcrumb.message,
    ];
    _crashlytics.log(parts.join(' '));
  }

  @override
  void setUser({required String id, String? email, String? name}) {
    _crashlytics.setUserIdentifier(id);
  }

  @override
  void clearUser() {
    _crashlytics.setUserIdentifier('');
  }

  @override
  void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }

  @override
  Future<void> flush() async {
    // Crashlytics flushes automatically; nothing to do here.
  }

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled({required bool enabled}) {
    _enabled = enabled;
    _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  bool _enabled = true;
}
