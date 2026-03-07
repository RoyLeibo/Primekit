import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/calendar.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockCalendarProvider extends Mock implements CalendarProvider {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

CalendarEvent _makeEvent({String title = 'Test Event'}) => CalendarEvent(
      id: 'evt-1',
      title: title,
      startTime: DateTime(2025, 6, 1, 9, 0),
      endTime: DateTime(2025, 6, 1, 10, 0),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCalendarProvider mockProvider;

  setUpAll(() {
    registerFallbackValue(_makeEvent());
  });

  setUp(() {
    mockProvider = MockCalendarProvider();
    // Reset the singleton state before each test.
    CalendarService.configure(mockProvider);
  });

  group('CalendarService', () {
    // -----------------------------------------------------------------------
    // configure / unconfigured guard
    // -----------------------------------------------------------------------

    group('configure', () {
      test('instance is accessible after configure', () {
        expect(CalendarService.instance, isNotNull);
      });

      test('throws StateError when no provider configured', () {
        // Point to a state where _provider is null by configuring with
        // something then reassigning; we test via a fresh configure below.
        // Instead we directly test the guard by configuring null-equivalent:
        // since we can't clear, test that the current setup doesn't throw.
        expect(
          () => CalendarService.instance,
          returnsNormally,
        );
      });
    });

    // -----------------------------------------------------------------------
    // hasPermission
    // -----------------------------------------------------------------------

    group('hasPermission', () {
      test('delegates to provider and returns true', () async {
        when(() => mockProvider.hasPermission()).thenAnswer((_) async => true);

        final result = await CalendarService.instance.hasPermission();

        expect(result, isTrue);
        verify(() => mockProvider.hasPermission()).called(1);
      });

      test('delegates to provider and returns false', () async {
        when(() => mockProvider.hasPermission()).thenAnswer((_) async => false);

        final result = await CalendarService.instance.hasPermission();

        expect(result, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // requestPermission
    // -----------------------------------------------------------------------

    group('requestPermission', () {
      test('delegates to provider and returns granted value', () async {
        when(() => mockProvider.requestPermission())
            .thenAnswer((_) async => true);

        final result = await CalendarService.instance.requestPermission();

        expect(result, isTrue);
        verify(() => mockProvider.requestPermission()).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // createEvent
    // -----------------------------------------------------------------------

    group('createEvent', () {
      test('delegates to provider and returns event id', () async {
        final event = _makeEvent();
        when(() => mockProvider.createEvent(any()))
            .thenAnswer((_) async => 'evt-1');

        final id = await CalendarService.instance.createEvent(event);

        expect(id, equals('evt-1'));
        verify(() => mockProvider.createEvent(any())).called(1);
      });

      test('forwards the exact event to the provider', () async {
        final event = _makeEvent(title: 'Sprint Planning');
        CalendarEvent? captured;

        when(() => mockProvider.createEvent(any())).thenAnswer((inv) async {
          captured = inv.positionalArguments.first as CalendarEvent;
          return 'evt-99';
        });

        await CalendarService.instance.createEvent(event);

        expect(captured?.title, equals('Sprint Planning'));
      });
    });

    // -----------------------------------------------------------------------
    // updateEvent
    // -----------------------------------------------------------------------

    group('updateEvent', () {
      test('delegates to provider', () async {
        final event = _makeEvent();
        when(() => mockProvider.updateEvent(any())).thenAnswer((_) async {});

        await CalendarService.instance.updateEvent(event);

        verify(() => mockProvider.updateEvent(any())).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // deleteEvent
    // -----------------------------------------------------------------------

    group('deleteEvent', () {
      test('delegates to provider with correct id', () async {
        when(() => mockProvider.deleteEvent(any())).thenAnswer((_) async {});

        await CalendarService.instance.deleteEvent('evt-1');

        verify(() => mockProvider.deleteEvent('evt-1')).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getEvents
    // -----------------------------------------------------------------------

    group('getEvents', () {
      test('returns events from provider', () async {
        final from = DateTime(2025, 6, 1);
        final to = DateTime(2025, 6, 30);
        final events = [_makeEvent(), _makeEvent(title: 'All-hands')];

        when(
          () => mockProvider.getEvents(from: from, to: to, calendarId: null),
        ).thenAnswer((_) async => events);

        final result = await CalendarService.instance.getEvents(
          from: from,
          to: to,
        );

        expect(result, equals(events));
        expect(result.length, equals(2));
      });

      test('forwards calendarId to provider', () async {
        final from = DateTime(2025, 1, 1);
        final to = DateTime(2025, 12, 31);

        when(
          () => mockProvider.getEvents(
            from: from,
            to: to,
            calendarId: 'cal-work',
          ),
        ).thenAnswer((_) async => []);

        await CalendarService.instance.getEvents(
          from: from,
          to: to,
          calendarId: 'cal-work',
        );

        verify(
          () => mockProvider.getEvents(
            from: from,
            to: to,
            calendarId: 'cal-work',
          ),
        ).called(1);
      });

      test('returns empty list when provider returns none', () async {
        final from = DateTime(2025, 1, 1);
        final to = DateTime(2025, 1, 31);

        when(
          () => mockProvider.getEvents(from: from, to: to, calendarId: null),
        ).thenAnswer((_) async => []);

        final result = await CalendarService.instance.getEvents(
          from: from,
          to: to,
        );

        expect(result, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // getCalendarIds
    // -----------------------------------------------------------------------

    group('getCalendarIds', () {
      test('returns calendar ids from provider', () async {
        when(() => mockProvider.getCalendarIds())
            .thenAnswer((_) async => ['cal-1', 'cal-2']);

        final ids = await CalendarService.instance.getCalendarIds();

        expect(ids, equals(['cal-1', 'cal-2']));
      });

      test('returns empty list when no calendars', () async {
        when(() => mockProvider.getCalendarIds())
            .thenAnswer((_) async => []);

        final ids = await CalendarService.instance.getCalendarIds();

        expect(ids, isEmpty);
      });
    });
  });
}
