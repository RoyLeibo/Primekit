import '../core/logger.dart';
import 'audit_backend.dart';
import 'audit_event.dart';
import 'audit_query.dart';

/// Central service for recording and querying audit events.
///
/// Configure once at app startup with a [AuditBackend] and your [appId]:
///
/// ```dart
/// AuditLogService.instance.configure(
///   FirestoreAuditBackend(firestore: FirebaseFirestore.instance),
///   appId: 'bullseye',
/// );
/// ```
///
/// Then log events anywhere in your app:
///
/// ```dart
/// AuditLogService.instance.log(
///   AuditEvent(
///     eventType: 'guess_submitted',
///     userId: user.id,
///     appId: AuditLogService.instance.appId,
///     resourceId: match.id,
///     resourceType: 'match',
///     payload: {'home': 2, 'away': 1},
///   ),
/// );
/// ```
///
/// Query events with flexible filters:
///
/// ```dart
/// final events = await AuditLogService.instance.query(
///   AuditQuery(userId: user.id, eventType: 'guess_submitted', limit: 20),
/// );
/// ```
class AuditLogService {
  AuditLogService._();

  static final AuditLogService _instance = AuditLogService._();

  /// The shared singleton instance.
  static AuditLogService get instance => _instance;

  AuditBackend? _backend;
  String _appId = 'unknown';
  bool _enabled = true;

  static const String _tag = 'AuditLogService';

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the service with a [backend] and the app's identifier.
  ///
  /// Must be called before [log] or [query]. Safe to call multiple times
  /// (e.g. to swap backends in tests).
  void configure(
    AuditBackend backend, {
    required String appId,
    bool enabled = true,
  }) {
    _backend = backend;
    _appId = appId;
    _enabled = enabled;
    PrimekitLogger.info(
      'AuditLogService configured — appId: $appId, enabled: $enabled',
      tag: _tag,
    );
  }

  /// The app identifier set during [configure].
  String get appId => _appId;

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Records [event] asynchronously. Fire-and-forget: never throws.
  ///
  /// Silently no-ops when [configure] has not been called or when
  /// [enabled] is false.
  void log(AuditEvent event) {
    if (!_enabled || _backend == null) return;
    _writeAsync(event);
  }

  /// Convenience method to log an event without constructing [AuditEvent]
  /// manually.
  ///
  /// [appId] defaults to the value set during [configure].
  void logEvent({
    required String eventType,
    required String userId,
    String? appId,
    String? resourceId,
    String? resourceType,
    Map<String, dynamic> payload = const {},
    Map<String, dynamic> metadata = const {},
  }) {
    log(
      AuditEvent(
        eventType: eventType,
        userId: userId,
        appId: appId ?? _appId,
        resourceId: resourceId,
        resourceType: resourceType,
        payload: payload,
        metadata: metadata,
      ),
    );
  }

  void _writeAsync(AuditEvent event) {
    _backend!.write(event).catchError((Object e, StackTrace st) {
      PrimekitLogger.error(
        'Failed to write audit event "${event.eventType}"',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns events matching [query].
  ///
  /// Returns an empty list if not configured or on failure.
  Future<List<AuditEvent>> query(AuditQuery query) async {
    if (_backend == null) {
      PrimekitLogger.warning(
        'AuditLogService.query() called before configure()',
        tag: _tag,
      );
      return [];
    }
    return _backend!.query(query);
  }

  /// Returns a live stream of events matching [query].
  ///
  /// Emits an empty list if not configured.
  Stream<List<AuditEvent>> watch(AuditQuery query) {
    if (_backend == null) return Stream.value([]);
    return _backend!.watch(query);
  }

  // ---------------------------------------------------------------------------
  // Control
  // ---------------------------------------------------------------------------

  /// Enables or disables event logging without removing the backend.
  void setEnabled(bool enabled) => _enabled = enabled;
}
