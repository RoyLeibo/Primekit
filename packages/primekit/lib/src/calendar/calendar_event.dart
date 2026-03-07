/// A platform-agnostic calendar event.
class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.id,
    this.description,
    this.location,
    this.isAllDay = false,
    this.recurrenceRule,
    this.calendarId,
  });

  final String? id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? location;
  final bool isAllDay;
  final String? recurrenceRule;
  final String? calendarId;

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
    bool? isAllDay,
    String? recurrenceRule,
    String? calendarId,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        description: description ?? this.description,
        location: location ?? this.location,
        isAllDay: isAllDay ?? this.isAllDay,
        recurrenceRule: recurrenceRule ?? this.recurrenceRule,
        calendarId: calendarId ?? this.calendarId,
      );
}
