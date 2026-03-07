import 'calendar_event.dart';

/// Abstract interface for calendar integrations.
///
/// Implement this to add support for Google Calendar, Apple Calendar,
/// Outlook, or any other calendar service.
///
/// ```dart
/// CalendarService.configure(GoogleCalendarProvider(...));
/// ```
abstract class CalendarProvider {
  /// Returns true if the user has granted calendar access.
  Future<bool> hasPermission();

  /// Requests calendar access. Returns true if granted.
  Future<bool> requestPermission();

  /// Creates a calendar event. Returns the created event's ID.
  Future<String> createEvent(CalendarEvent event);

  /// Updates an existing event.
  Future<void> updateEvent(CalendarEvent event);

  /// Deletes an event by ID.
  Future<void> deleteEvent(String eventId);

  /// Fetches events in a time range.
  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
    String? calendarId,
  });

  /// Returns available calendar IDs (e.g. multiple Google accounts).
  Future<List<String>> getCalendarIds();
}
