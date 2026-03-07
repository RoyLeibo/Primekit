import 'package:primekit_core/primekit_core.dart';
import 'calendar_event.dart';
import 'calendar_provider.dart';

/// Unified calendar service. Configure once, use anywhere.
///
/// ```dart
/// CalendarService.configure(GoogleCalendarProvider(...));
/// await CalendarService.instance.createEvent(event);
/// ```
class CalendarService {
  CalendarService._();

  static CalendarService? _instance;
  static CalendarProvider? _provider;
  static const String _tag = 'CalendarService';

  static CalendarService get instance {
    _instance ??= CalendarService._();
    return _instance!;
  }

  /// Configure with a provider before calling any other method.
  static void configure(CalendarProvider provider) {
    _provider = provider;
    PrimekitLogger.debug(
      'CalendarService configured with ${provider.runtimeType}',
      tag: _tag,
    );
  }

  CalendarProvider get _p {
    if (_provider == null) {
      throw StateError(
        'CalendarService not configured. Call CalendarService.configure() first.',
      );
    }
    return _provider!;
  }

  Future<bool> hasPermission() => _p.hasPermission();
  Future<bool> requestPermission() => _p.requestPermission();

  Future<String> createEvent(CalendarEvent event) async {
    PrimekitLogger.debug('Creating event: ${event.title}', tag: _tag);
    return _p.createEvent(event);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    PrimekitLogger.debug('Updating event: ${event.id}', tag: _tag);
    return _p.updateEvent(event);
  }

  Future<void> deleteEvent(String eventId) async {
    PrimekitLogger.debug('Deleting event: $eventId', tag: _tag);
    return _p.deleteEvent(eventId);
  }

  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
    String? calendarId,
  }) => _p.getEvents(from: from, to: to, calendarId: calendarId);

  Future<List<String>> getCalendarIds() => _p.getCalendarIds();
}
