import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:primekit/analytics.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAnalyticsProvider extends Mock implements AnalyticsProvider {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late SessionTracker tracker;
  late MockAnalyticsProvider mockProvider;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent(name: 'fallback'));
  });

  setUp(() async {
    // Provide an in-memory SharedPreferences for persistence calls.
    SharedPreferences.setMockInitialValues({});

    mockProvider = MockAnalyticsProvider();
    when(() => mockProvider.name).thenReturn('mock');
    when(() => mockProvider.initialize()).thenAnswer((_) async {});
    when(() => mockProvider.logEvent(any())).thenAnswer((_) async {});

    await EventTracker.instance.configure([mockProvider]);

    tracker = SessionTracker.instance;
    tracker.resetForTesting();
  });

  tearDown(() {
    tracker.resetForTesting();
    EventTracker.instance.resetForTesting();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('sessionCount starts at 0', () {
      expect(tracker.sessionCount, 0);
    });

    test('currentSessionDuration is zero when no session active', () {
      expect(tracker.currentSessionDuration, Duration.zero);
    });
  });

  // -------------------------------------------------------------------------
  // startSession
  // -------------------------------------------------------------------------

  group('startSession()', () {
    test('increments sessionCount by 1', () async {
      await tracker.startSession();
      expect(tracker.sessionCount, 1);
    });

    test('emits SessionStartedEvent on the events stream', () async {
      final eventFuture = tracker.events.first;
      await tracker.startSession();
      final event = await eventFuture;
      expect(event, isA<SessionStartedEvent>());
    });

    test('SessionStartedEvent contains correct sessionCount', () async {
      final eventFuture = tracker.events.first;
      await tracker.startSession();
      final event = await eventFuture as SessionStartedEvent;
      expect(event.sessionCount, 1);
    });

    test('currentSessionDuration is positive after starting', () async {
      await tracker.startSession();
      expect(
        tracker.currentSessionDuration,
        greaterThanOrEqualTo(Duration.zero),
      );
    });

    test('calling startSession twice keeps original session', () async {
      await tracker.startSession();
      final count = tracker.sessionCount;
      await tracker.startSession(); // Should be a no-op.
      expect(tracker.sessionCount, count);
    });

    test('logs session_start analytics event', () async {
      await tracker.startSession();
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockProvider.logEvent(captureAny())).captured;
      final events = captured.cast<AnalyticsEvent>();
      expect(events.any((e) => e.name == 'session_start'), isTrue);
    });

    test('increments sessionCount across multiple sessions', () async {
      await tracker.startSession();
      await tracker.endSession();
      await tracker.startSession();
      expect(tracker.sessionCount, 2);
    });
  });

  // -------------------------------------------------------------------------
  // endSession
  // -------------------------------------------------------------------------

  group('endSession()', () {
    test('emits SessionEndedEvent', () async {
      await tracker.startSession();
      final eventFuture = tracker.events.first;
      await tracker.endSession();
      final event = await eventFuture;
      expect(event, isA<SessionEndedEvent>());
    });

    test('SessionEndedEvent contains non-negative duration', () async {
      await tracker.startSession();
      final eventFuture = tracker.events.first;
      await tracker.endSession();
      final event = await eventFuture as SessionEndedEvent;
      expect(event.duration, greaterThanOrEqualTo(Duration.zero));
    });

    test('resets currentSessionDuration to zero', () async {
      await tracker.startSession();
      await tracker.endSession();
      expect(tracker.currentSessionDuration, Duration.zero);
    });

    test('is a no-op when no session is active', () async {
      // Should complete without error or emitting an event.
      final events = <SessionEvent>[];
      final sub = tracker.events.listen(events.add);
      await tracker.endSession();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, isEmpty);
    });

    test('logs session_end analytics event', () async {
      await tracker.startSession();
      await tracker.endSession();
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockProvider.logEvent(captureAny())).captured;
      final events = captured.cast<AnalyticsEvent>();
      expect(events.any((e) => e.name == 'session_end'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // recordActivity
  // -------------------------------------------------------------------------

  group('recordActivity()', () {
    test('does not throw when no session is active', () {
      expect(() => tracker.recordActivity(), returnsNormally);
    });

    test('can be called when a session is active', () async {
      await tracker.startSession();
      expect(() => tracker.recordActivity(), returnsNormally);
      await tracker.endSession();
    });
  });

  // -------------------------------------------------------------------------
  // Idle detection
  // -------------------------------------------------------------------------

  group('idle detection', () {
    test('emits SessionIdleEvent after 5 minutes of inactivity', () {
      fakeAsync((async) {
        // Start a session and set up listener before advancing time.
        tracker.startSession();

        SessionEvent? captured;
        tracker.events.listen((event) {
          if (event is SessionIdleEvent) captured = event;
        });

        // Advance past the 5-minute threshold.
        async.elapse(const Duration(minutes: 6));

        expect(captured, isA<SessionIdleEvent>());
      });
    });

    test('recordActivity resets the idle timer', () {
      fakeAsync((async) {
        tracker.startSession();

        SessionIdleEvent? idleEvent;
        tracker.events.listen((event) {
          if (event is SessionIdleEvent) idleEvent = event;
        });

        // Advance 4 minutes — still before threshold.
        async.elapse(const Duration(minutes: 4));
        tracker.recordActivity();

        // Advance another 4 minutes from activity (8 min total, but timer reset).
        async.elapse(const Duration(minutes: 4));

        // Should not have fired yet (only 4 min since last activity).
        expect(idleEvent, isNull);

        // Advance past threshold.
        async.elapse(const Duration(minutes: 2));
        expect(idleEvent, isA<SessionIdleEvent>());
      });
    });

    test('no idle event is emitted when session is ended before threshold', () {
      fakeAsync((async) {
        tracker.startSession();

        SessionIdleEvent? idleEvent;
        tracker.events.listen((event) {
          if (event is SessionIdleEvent) idleEvent = event;
        });

        async.elapse(const Duration(minutes: 3));
        tracker.endSession();
        async.elapse(const Duration(minutes: 10));

        expect(idleEvent, isNull);
      });
    });
  });

  // -------------------------------------------------------------------------
  // events stream
  // -------------------------------------------------------------------------

  group('events stream', () {
    test('is a broadcast stream', () {
      expect(tracker.events.isBroadcast, isTrue);
    });

    test('multiple subscribers receive the same events', () async {
      final events1 = <SessionEvent>[];
      final events2 = <SessionEvent>[];

      final sub1 = tracker.events.listen(events1.add);
      final sub2 = tracker.events.listen(events2.add);

      await tracker.startSession();
      await Future<void>.delayed(Duration.zero);

      await sub1.cancel();
      await sub2.cancel();

      expect(events1, hasLength(1));
      expect(events2, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // resetForTesting
  // -------------------------------------------------------------------------

  group('resetForTesting()', () {
    test('resets sessionCount to 0', () async {
      await tracker.startSession();
      tracker.resetForTesting();
      expect(tracker.sessionCount, 0);
    });

    test('resets currentSessionDuration to zero', () async {
      await tracker.startSession();
      tracker.resetForTesting();
      expect(tracker.currentSessionDuration, Duration.zero);
    });
  });
}
