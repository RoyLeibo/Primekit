import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:primekit/membership.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late SharedPreferences prefs;
  late TrialManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    manager = TrialManager(preferences: prefs);
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // startTrial
  // -------------------------------------------------------------------------

  group('startTrial()', () {
    test('emits TrialEventStarted on the events stream', () async {
      final eventFuture = manager.events.first;

      await manager.startTrial('pro', duration: const Duration(days: 7));

      final event = await eventFuture;
      expect(event, isA<TrialEventStarted>());
    });

    test('TrialEventStarted contains correct productId', () async {
      final eventFuture = manager.events.first;

      await manager.startTrial('pro_monthly', duration: const Duration(days: 7));

      final event = await eventFuture as TrialEventStarted;
      expect(event.productId, 'pro_monthly');
    });

    test('TrialEventStarted trialEnds is approximately 7 days from now',
        () async {
      final before = DateTime.now().toUtc();
      final eventFuture = manager.events.first;

      await manager.startTrial('pro', duration: const Duration(days: 7));

      final event = await eventFuture as TrialEventStarted;
      final after = DateTime.now().toUtc();

      expect(
        event.trialEnds.isAfter(before.add(const Duration(days: 6))),
        isTrue,
      );
      expect(
        event.trialEnds.isBefore(after.add(const Duration(days: 8))),
        isTrue,
      );
    });

    test('persists trial end date to SharedPreferences', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));

      final raw = prefs.getString('pk_trial_end_pro');
      expect(raw, isNotNull);
    });

    test('replacing an active trial updates the end date', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));
      final first = prefs.getString('pk_trial_end_pro');

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await manager.startTrial('pro', duration: const Duration(days: 14));
      final second = prefs.getString('pk_trial_end_pro');

      expect(first, isNot(equals(second)));
    });
  });

  // -------------------------------------------------------------------------
  // isInTrial
  // -------------------------------------------------------------------------

  group('isInTrial()', () {
    test('returns true for an active trial', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));
      expect(await manager.isInTrial('pro'), isTrue);
    });

    test('returns false for a product with no trial', () async {
      expect(await manager.isInTrial('pro'), isFalse);
    });

    test('returns false for a product with an already-expired trial', () async {
      // Set an end date in the past directly via prefs.
      await prefs.setString(
        'pk_trial_end_pro',
        DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
      );
      expect(await manager.isInTrial('pro'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getRemainingTime
  // -------------------------------------------------------------------------

  group('getRemainingTime()', () {
    test('returns a positive duration for an active trial', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));
      final remaining = await manager.getRemainingTime('pro');
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });

    test('returns null for a product with no trial', () async {
      expect(await manager.getRemainingTime('pro'), isNull);
    });

    test('returns null for an expired trial', () async {
      await prefs.setString(
        'pk_trial_end_pro',
        DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
      );
      expect(await manager.getRemainingTime('pro'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // getTrialEndDate
  // -------------------------------------------------------------------------

  group('getTrialEndDate()', () {
    test('returns non-null date after startTrial', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));
      expect(await manager.getTrialEndDate('pro'), isNotNull);
    });

    test('returns null when no trial exists', () async {
      expect(await manager.getTrialEndDate('pro'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // endTrial
  // -------------------------------------------------------------------------

  group('endTrial()', () {
    test('emits TrialEventEnded event', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));

      // Consume the started event.
      await manager.events.first;

      final endedFuture = manager.events.first;
      await manager.endTrial('pro');
      final event = await endedFuture;

      expect(event, isA<TrialEventEnded>());
      expect((event as TrialEventEnded).productId, 'pro');
    });

    test('isInTrial returns false after endTrial', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));
      await manager.endTrial('pro');
      expect(await manager.isInTrial('pro'), isFalse);
    });

    test('removes persisted end date from SharedPreferences', () async {
      await manager.startTrial('pro', duration: const Duration(days: 7));
      await manager.endTrial('pro');
      expect(prefs.getString('pk_trial_end_pro'), isNull);
    });

    test('does not emit event when no trial exists', () async {
      final events = <TrialEvent>[];
      final sub = manager.events.listen(events.add);

      await manager.endTrial('pro');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // eventsFor
  // -------------------------------------------------------------------------

  group('eventsFor()', () {
    test('only emits events for the specified productId', () async {
      final proEvents = <TrialEvent>[];
      final sub = manager.eventsFor('pro').listen(proEvents.add);

      await manager.startTrial('enterprise', duration: const Duration(days: 7));
      await manager.startTrial('pro', duration: const Duration(days: 3));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(proEvents.length, 1);
      expect((proEvents.first as TrialEventStarted).productId, 'pro');
    });
  });

  // -------------------------------------------------------------------------
  // Periodic expiry check
  // -------------------------------------------------------------------------

  group('periodic expiry check', () {
    test('emits TrialEventEnded when trial expires during periodic check', () {
      fakeAsync((async) {
        final events = <TrialEvent>[];
        manager.events.listen(events.add);

        // Set a trial ending in 30 minutes (less than 1-hour check interval,
        // but the check fires at T+1h which is past the trial).
        prefs.setString(
          'pk_trial_end_pro',
          DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 30))
              .toIso8601String(),
        );
        prefs.setString(
          'pk_trial_started_pro',
          DateTime.now().toUtc().toIso8601String(),
        );

        // Advance past the trial end AND trigger the periodic check.
        async.elapse(const Duration(hours: 2));

        expect(
          events.any((e) => e is TrialEventEnded && e.productId == 'pro'),
          isTrue,
        );
      });
    });

    test(
        'emits TrialEventEndingSoon when remaining time is within 24 hours',
        () {
      fakeAsync((async) {
        final events = <TrialEvent>[];
        manager.events.listen(events.add);

        // Set a trial ending in ~12 hours (within ending-soon threshold).
        prefs.setString(
          'pk_trial_end_pro',
          DateTime.now()
              .toUtc()
              .add(const Duration(hours: 12))
              .toIso8601String(),
        );
        prefs.setString(
          'pk_trial_started_pro',
          DateTime.now().toUtc().toIso8601String(),
        );

        // Trigger the hourly check.
        async.elapse(const Duration(hours: 1));

        expect(
          events.any((e) => e is TrialEventEndingSoon && e.productId == 'pro'),
          isTrue,
        );
      });
    });

    test('ending-soon is only emitted once per session', () {
      fakeAsync((async) {
        final endingSoonEvents = <TrialEventEndingSoon>[];
        manager.events.listen((e) {
          if (e is TrialEventEndingSoon) endingSoonEvents.add(e);
        });

        prefs.setString(
          'pk_trial_end_pro',
          DateTime.now()
              .toUtc()
              .add(const Duration(hours: 12))
              .toIso8601String(),
        );
        prefs.setString(
          'pk_trial_started_pro',
          DateTime.now().toUtc().toIso8601String(),
        );

        // Trigger two consecutive hourly checks.
        async.elapse(const Duration(hours: 1));
        async.elapse(const Duration(hours: 1));

        expect(endingSoonEvents.length, 1);
      });
    });
  });

  // -------------------------------------------------------------------------
  // events stream
  // -------------------------------------------------------------------------

  group('events stream', () {
    test('is a broadcast stream', () {
      expect(manager.events.isBroadcast, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose()', () {
    test('closes the event stream after dispose', () async {
      final newManager = TrialManager(preferences: prefs);
      final done = newManager.events.isEmpty; // subscribes first
      newManager.dispose();
      expect(await done, isTrue);
    });
  });
}
