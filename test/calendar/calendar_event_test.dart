import 'package:test/test.dart';
import 'package:primekit/calendar.dart';

void main() {
  // -------------------------------------------------------------------------
  // Fixtures
  // -------------------------------------------------------------------------

  final start = DateTime(2025, 6, 1, 9, 0);
  final end = DateTime(2025, 6, 1, 10, 0);

  CalendarEvent makeEvent({
    String? id,
    String title = 'Team Standup',
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
    bool isAllDay = false,
    String? recurrenceRule,
    String? calendarId,
  }) => CalendarEvent(
    id: id,
    title: title,
    startTime: startTime ?? start,
    endTime: endTime ?? end,
    description: description,
    location: location,
    isAllDay: isAllDay,
    recurrenceRule: recurrenceRule,
    calendarId: calendarId,
  );

  // -------------------------------------------------------------------------
  // Tests
  // -------------------------------------------------------------------------

  group('CalendarEvent', () {
    // -----------------------------------------------------------------------
    // Construction
    // -----------------------------------------------------------------------

    group('construction', () {
      test('creates event with required fields', () {
        final event = makeEvent();
        expect(event.title, equals('Team Standup'));
        expect(event.startTime, equals(start));
        expect(event.endTime, equals(end));
      });

      test('id is null by default', () {
        final event = makeEvent();
        expect(event.id, isNull);
      });

      test('description is null by default', () {
        final event = makeEvent();
        expect(event.description, isNull);
      });

      test('location is null by default', () {
        final event = makeEvent();
        expect(event.location, isNull);
      });

      test('isAllDay defaults to false', () {
        final event = makeEvent();
        expect(event.isAllDay, isFalse);
      });

      test('recurrenceRule is null by default', () {
        final event = makeEvent();
        expect(event.recurrenceRule, isNull);
      });

      test('calendarId is null by default', () {
        final event = makeEvent();
        expect(event.calendarId, isNull);
      });

      test('stores all optional fields when provided', () {
        final event = makeEvent(
          id: 'evt-1',
          description: 'Daily sync',
          location: 'Room A',
          isAllDay: true,
          recurrenceRule: 'FREQ=DAILY',
          calendarId: 'cal-primary',
        );

        expect(event.id, equals('evt-1'));
        expect(event.description, equals('Daily sync'));
        expect(event.location, equals('Room A'));
        expect(event.isAllDay, isTrue);
        expect(event.recurrenceRule, equals('FREQ=DAILY'));
        expect(event.calendarId, equals('cal-primary'));
      });
    });

    // -----------------------------------------------------------------------
    // copyWith
    // -----------------------------------------------------------------------

    group('copyWith', () {
      test('returns new event with updated title', () {
        final original = makeEvent(title: 'Original');
        final updated = original.copyWith(title: 'Updated');

        expect(updated.title, equals('Updated'));
        expect(original.title, equals('Original'));
      });

      test('preserves unchanged fields', () {
        final original = makeEvent(
          id: 'evt-1',
          title: 'Stand-up',
          description: 'Daily',
          location: 'Zoom',
          isAllDay: false,
          recurrenceRule: 'FREQ=WEEKLY',
          calendarId: 'cal-1',
        );
        final updated = original.copyWith(title: 'Updated');

        expect(updated.id, equals('evt-1'));
        expect(updated.startTime, equals(start));
        expect(updated.endTime, equals(end));
        expect(updated.description, equals('Daily'));
        expect(updated.location, equals('Zoom'));
        expect(updated.isAllDay, isFalse);
        expect(updated.recurrenceRule, equals('FREQ=WEEKLY'));
        expect(updated.calendarId, equals('cal-1'));
      });

      test('can update startTime', () {
        final original = makeEvent();
        final newStart = DateTime(2025, 7, 1, 8, 0);
        final updated = original.copyWith(startTime: newStart);

        expect(updated.startTime, equals(newStart));
      });

      test('can update endTime', () {
        final original = makeEvent();
        final newEnd = DateTime(2025, 7, 1, 11, 0);
        final updated = original.copyWith(endTime: newEnd);

        expect(updated.endTime, equals(newEnd));
      });

      test('can update isAllDay from false to true', () {
        final original = makeEvent(isAllDay: false);
        final updated = original.copyWith(isAllDay: true);

        expect(updated.isAllDay, isTrue);
      });

      test('can update id', () {
        final original = makeEvent();
        final updated = original.copyWith(id: 'new-id');

        expect(updated.id, equals('new-id'));
      });

      test('returns a distinct object (not same reference)', () {
        final original = makeEvent();
        final updated = original.copyWith(title: 'Different');

        expect(identical(original, updated), isFalse);
      });
    });
  });
}
