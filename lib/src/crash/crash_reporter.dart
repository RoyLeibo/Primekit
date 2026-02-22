/// Severity level of a [Breadcrumb].
enum BreadcrumbLevel {
  /// Verbose diagnostic information.
  debug,

  /// General informational message.
  info,

  /// Potential issue that did not cause an error.
  warning,

  /// An error occurred.
  error,

  /// A fatal, unrecoverable error.
  fatal,
}

/// The category of event a [Breadcrumb] describes.
enum BreadcrumbType {
  /// A screen or route change.
  navigation,

  /// A user-initiated action (button tap, swipe, etc.).
  userAction,

  /// An outgoing or incoming network request.
  network,

  /// An error or exception.
  error,

  /// General informational event.
  info,
}

/// An immutable record of a discrete event that occurred before a crash.
///
/// Breadcrumbs form a trail that helps diagnose what led to a crash.
class Breadcrumb {
  /// Creates a [Breadcrumb].
  ///
  /// [timestamp] defaults to [DateTime.now] when omitted.
  Breadcrumb({
    required this.message,
    required this.type,
    this.data,
    DateTime? timestamp,
    this.category,
    this.level = BreadcrumbLevel.info,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Human-readable description of the event.
  final String message;

  /// The type of event.
  final BreadcrumbType type;

  /// Optional structured data attached to this breadcrumb.
  final Map<String, dynamic>? data;

  /// When this breadcrumb was recorded.
  final DateTime timestamp;

  /// Logical grouping, e.g. `'navigation'`, `'user_action'`, `'network'`.
  final String? category;

  /// The severity of this breadcrumb.
  final BreadcrumbLevel level;

  @override
  String toString() =>
      'Breadcrumb(${level.name}) [${category ?? type.name}] $message';
}

/// Contract that every crash-reporting backend must satisfy.
///
/// Implementations include `FirebaseCrashReporter`, `SentryCrashReporter`,
/// and `MultiCrashReporter` (fan-out).
abstract interface class CrashReporter {
  /// Performs one-time initialisation of the underlying SDK.
  Future<void> initialize();

  /// Records [error] with optional [stackTrace] and contextual [reason].
  ///
  /// Set [fatal] to `true` for crashes that terminated the app.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  });

  /// Appends [breadcrumb] to the trail of events leading up to a crash.
  void addBreadcrumb(Breadcrumb breadcrumb);

  /// Associates subsequent reports with the given user [id].
  void setUser({required String id, String? email, String? name});

  /// Removes the current user association.
  void clearUser();

  /// Attaches a persistent key-value pair to every report.
  void setCustomKey(String key, Object value);

  /// Flushes any pending crash reports to the backend.
  Future<void> flush();

  /// Whether crash reporting is currently active.
  bool get isEnabled;

  /// Enables or disables crash reporting at runtime.
  void setEnabled({required bool enabled});
}
