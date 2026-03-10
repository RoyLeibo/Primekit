import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

import '../../core.dart';
import 'calendar_event.dart';
import 'calendar_provider.dart';

/// Google Calendar implementation of [CalendarProvider].
///
/// Uses the `google_sign_in 7.x` singleton API to obtain OAuth credentials
/// via `GoogleSignIn.instance.authorizationClient.authorizationForScopes()`,
/// then converts the authorization to a `googleapis` HTTP client via the
/// `extension_google_sign_in_as_googleapis_auth` package.
///
/// Automatically retries on `401 / 403` by re-requesting authorization.
///
/// **Setup (include calendar scopes when authenticating):**
/// ```dart
/// // In your AuthService.signInWithGoogle():
/// await GoogleSignIn.instance.authenticate(
///   scopeHint: [
///     'email',
///     'profile',
///     'https://www.googleapis.com/auth/calendar.events',
///     'https://www.googleapis.com/auth/calendar.readonly',
///   ],
/// );
/// ```
///
/// **Configure once at app start (after Firebase init):**
/// ```dart
/// CalendarService.configure(GoogleCalendarProvider());
/// ```
///
/// **Then use CalendarService anywhere:**
/// ```dart
/// await CalendarService.instance.createEvent(event);
/// final calendars = await GoogleCalendarProvider.instance.getCalendarList();
/// ```
class GoogleCalendarProvider implements CalendarProvider {
  GoogleCalendarProvider();

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  static const String _tag = 'GoogleCalendarProvider';

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  @override
  Future<bool> hasPermission() async {
    try {
      final authorization = await GoogleSignIn.instance.authorizationClient
          .authorizationForScopes(_scopes);
      return authorization != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final authorization = await GoogleSignIn.instance.authorizationClient
          .authorizationForScopes(_scopes);
      return authorization != null;
    } catch (e, st) {
      PrimekitLogger.error(
        'requestPermission failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<String> createEvent(CalendarEvent event) async {
    final api = await _getApi();
    final calendarId = event.calendarId ?? 'primary';
    final created = await _withRetry(
      () => api.events.insert(_toGcal(event), calendarId),
    );
    PrimekitLogger.debug(
      'Created event "${event.title}" (${created.id})',
      tag: _tag,
    );
    return created.id ?? '';
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    if (event.id == null) {
      throw ArgumentError('CalendarEvent.id is required for updateEvent()');
    }
    final api = await _getApi();
    final calendarId = event.calendarId ?? 'primary';
    await _withRetry(
      () => api.events.update(_toGcal(event), calendarId, event.id!),
    );
    PrimekitLogger.debug('Updated event "${event.id}"', tag: _tag);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final api = await _getApi();
    await _withRetry(() => api.events.delete('primary', eventId));
    PrimekitLogger.debug('Deleted event "$eventId"', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  @override
  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
    String? calendarId,
  }) async {
    final api = await _getApi();
    final result = await _withRetry(
      () => api.events.list(
        calendarId ?? 'primary',
        timeMin: from.toUtc(),
        timeMax: to.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      ),
    );
    return (result.items ?? [])
        .map(_fromGcal)
        .whereType<CalendarEvent>()
        .toList();
  }

  @override
  Future<List<String>> getCalendarIds() async {
    final list = await getCalendarList();
    return list.map((c) => c.id).toList();
  }

  /// Returns a list of `{id, name}` records for the user's calendars.
  ///
  /// Convenience method for building a calendar picker UI — gives both the
  /// machine-readable ID and the human-readable display name.
  Future<List<({String id, String name})>> getCalendarList() async {
    final api = await _getApi();
    final result = await _withRetry(() => api.calendarList.list());
    return (result.items ?? [])
        .where((c) => c.id != null)
        .map((c) => (id: c.id!, name: c.summary ?? c.id!))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a `CalendarApi` using fresh OAuth credentials.
  ///
  /// Uses `GoogleSignIn.instance.authorizationClient.authorizationForScopes()`
  /// (google_sign_in 7.x API) and converts to a `googleapis` `AuthClient`
  /// via `extension_google_sign_in_as_googleapis_auth`.
  Future<gcal.CalendarApi> _getApi() async {
    final authorization = await GoogleSignIn.instance.authorizationClient
        .authorizationForScopes(_scopes);

    if (authorization == null) {
      throw const AuthException(
        message: 'Could not obtain Google Calendar authorization. '
            'Ensure the user is signed in and calendar scopes were requested.',
        code: 'GOOGLE_CALENDAR_UNAUTHORIZED',
      );
    }

    return gcal.CalendarApi(authorization.authClient(scopes: _scopes));
  }

  /// Runs [action]. On a `401` or `403`, re-requests authorization and
  /// retries the action once.
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (!_isAuthError(e)) rethrow;

      PrimekitLogger.info(
        'Auth error — refreshing Google Calendar credentials and retrying',
        tag: _tag,
      );
      try {
        // Re-request authorization to force a token refresh.
        await GoogleSignIn.instance.authorizationClient
            .authorizationForScopes(_scopes);
        return await action();
      } catch (retryError, st) {
        PrimekitLogger.error(
          'Retry after re-auth failed',
          tag: _tag,
          error: retryError,
          stackTrace: st,
        );
        rethrow;
      }
    }
  }

  bool _isAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized') ||
        msg.contains('forbidden') ||
        msg.contains('insufficient');
  }

  // ---------------------------------------------------------------------------
  // Model conversion
  // ---------------------------------------------------------------------------

  gcal.Event _toGcal(CalendarEvent event) => gcal.Event(
    id: event.id,
    summary: event.title,
    description: event.description,
    location: event.location,
    start: event.isAllDay
        ? gcal.EventDateTime(date: event.startTime)
        : gcal.EventDateTime(
            dateTime: event.startTime.toUtc(),
            timeZone: 'UTC',
          ),
    end: event.isAllDay
        ? gcal.EventDateTime(date: event.endTime)
        : gcal.EventDateTime(
            dateTime: event.endTime.toUtc(),
            timeZone: 'UTC',
          ),
    recurrence: event.recurrenceRule != null ? [event.recurrenceRule!] : null,
  );

  CalendarEvent? _fromGcal(gcal.Event event) {
    final startTime = event.start?.dateTime ?? event.start?.date;
    final endTime = event.end?.dateTime ?? event.end?.date;
    if (startTime == null || endTime == null) return null;

    return CalendarEvent(
      id: event.id,
      title: event.summary ?? '',
      startTime: startTime,
      endTime: endTime,
      description: event.description,
      location: event.location,
      isAllDay: event.start?.date != null,
      recurrenceRule: event.recurrence?.firstOrNull,
    );
  }
}
