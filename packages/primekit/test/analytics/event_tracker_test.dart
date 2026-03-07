import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/analytics.dart';
import 'package:primekit_core/primekit_core.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAnalyticsProvider extends Mock implements AnalyticsProvider {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late EventTracker tracker;
  late MockAnalyticsProvider mockProvider;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent(name: 'fallback'));
  });

  setUp(() {
    tracker = EventTracker.instance;
    tracker.resetForTesting();
    mockProvider = MockAnalyticsProvider();
    when(() => mockProvider.name).thenReturn('mock_provider');
    when(() => mockProvider.initialize()).thenAnswer((_) async {});
    when(() => mockProvider.logEvent(any())).thenAnswer((_) async {});
    when(() => mockProvider.setUserId(any())).thenAnswer((_) async {});
    when(
      () => mockProvider.setUserProperty(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockProvider.reset()).thenAnswer((_) async {});
  });

  tearDown(() {
    tracker.resetForTesting();
  });

  // -------------------------------------------------------------------------
  // configure
  // -------------------------------------------------------------------------

  group('configure()', () {
    test('accepts a single provider and initialises it', () async {
      await tracker.configure([mockProvider]);

      verify(() => mockProvider.initialize()).called(1);
    });

    test('accepts multiple providers and initialises all', () async {
      final second = MockAnalyticsProvider();
      when(() => second.name).thenReturn('second_provider');
      when(() => second.initialize()).thenAnswer((_) async {});

      await tracker.configure([mockProvider, second]);

      verify(() => mockProvider.initialize()).called(1);
      verify(() => second.initialize()).called(1);
    });

    test(
      'throws ConfigurationException when providers list is empty',
      () async {
        await expectLater(
          tracker.configure([]),
          throwsA(isA<ConfigurationException>()),
        );
      },
    );

    test('reconfiguring replaces the previous provider list', () async {
      final second = MockAnalyticsProvider();
      when(() => second.name).thenReturn('second_provider');
      when(() => second.initialize()).thenAnswer((_) async {});
      when(() => second.logEvent(any())).thenAnswer((_) async {});

      await tracker.configure([mockProvider]);
      await tracker.configure([second]);

      final event = AnalyticsEvent(name: 'test_event');
      await tracker.logEvent(event);

      verifyNever(() => mockProvider.logEvent(any()));
      verify(() => second.logEvent(event)).called(1);
    });

    test(
      'provider initialisation failure is caught and does not rethrow',
      () async {
        when(
          () => mockProvider.initialize(),
        ).thenThrow(Exception('SDK init failed'));

        await expectLater(tracker.configure([mockProvider]), completes);
      },
    );
  });

  // -------------------------------------------------------------------------
  // logEvent
  // -------------------------------------------------------------------------

  group('logEvent()', () {
    setUp(() async {
      await tracker.configure([mockProvider]);
    });

    test('dispatches event to provider', () async {
      final event = AnalyticsEvent.screenView(screenName: 'HomeScreen');
      await tracker.logEvent(event);

      verify(() => mockProvider.logEvent(event)).called(1);
    });

    test('dispatches to multiple providers', () async {
      final second = MockAnalyticsProvider();
      when(() => second.name).thenReturn('second');
      when(() => second.initialize()).thenAnswer((_) async {});
      when(() => second.logEvent(any())).thenAnswer((_) async {});

      tracker.resetForTesting();
      await tracker.configure([mockProvider, second]);

      final event = AnalyticsEvent.purchase(
        amount: 9.99,
        currency: 'USD',
        productId: 'pro_monthly',
      );
      await tracker.logEvent(event);

      verify(() => mockProvider.logEvent(event)).called(1);
      verify(() => second.logEvent(event)).called(1);
    });

    test('is a no-op when tracker is disabled', () async {
      tracker.enabled = false;
      final event = AnalyticsEvent(name: 'should_not_log');
      await tracker.logEvent(event);

      verifyNever(() => mockProvider.logEvent(any()));
    });

    test('is a no-op before configure() is called', () async {
      tracker.resetForTesting();
      final event = AnalyticsEvent(name: 'early_event');
      await tracker.logEvent(event);

      verifyNever(() => mockProvider.logEvent(any()));
    });

    test('swallows provider-level errors without rethrowing', () async {
      when(
        () => mockProvider.logEvent(any()),
      ).thenThrow(Exception('backend down'));

      await expectLater(
        tracker.logEvent(AnalyticsEvent(name: 'risky')),
        completes,
      );
    });

    test('re-enables after being disabled', () async {
      tracker.enabled = false;
      tracker.enabled = true;

      final event = AnalyticsEvent(name: 're_enabled_event');
      await tracker.logEvent(event);

      verify(() => mockProvider.logEvent(event)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // enabled
  // -------------------------------------------------------------------------

  group('enabled getter/setter', () {
    test('defaults to true', () {
      expect(tracker.enabled, isTrue);
    });

    test('can be set to false', () {
      tracker.enabled = false;
      expect(tracker.enabled, isFalse);
    });

    test('can be toggled back to true', () {
      tracker.enabled = false;
      tracker.enabled = true;
      expect(tracker.enabled, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // setUserId
  // -------------------------------------------------------------------------

  group('setUserId()', () {
    setUp(() async {
      await tracker.configure([mockProvider]);
    });

    test('forwards userId to provider', () async {
      await tracker.setUserId('user_123');

      verify(() => mockProvider.setUserId('user_123')).called(1);
    });

    test('forwards null userId (sign-out) to provider', () async {
      await tracker.setUserId(null);

      verify(() => mockProvider.setUserId(null)).called(1);
    });

    test('is a no-op when disabled', () async {
      tracker.enabled = false;
      await tracker.setUserId('user_abc');

      verifyNever(() => mockProvider.setUserId(any()));
    });
  });

  // -------------------------------------------------------------------------
  // setUserProperty
  // -------------------------------------------------------------------------

  group('setUserProperty()', () {
    setUp(() async {
      await tracker.configure([mockProvider]);
    });

    test('forwards key-value pair to provider', () async {
      await tracker.setUserProperty('plan', 'pro');

      verify(() => mockProvider.setUserProperty('plan', 'pro')).called(1);
    });

    test('is a no-op when disabled', () async {
      tracker.enabled = false;
      await tracker.setUserProperty('plan', 'pro');

      verifyNever(() => mockProvider.setUserProperty(any(), any()));
    });
  });

  // -------------------------------------------------------------------------
  // reset
  // -------------------------------------------------------------------------

  group('reset()', () {
    setUp(() async {
      await tracker.configure([mockProvider]);
    });

    test('calls reset on provider', () async {
      await tracker.reset();

      verify(() => mockProvider.reset()).called(1);
    });

    test('is a no-op before configure()', () async {
      tracker.resetForTesting();
      await tracker.reset();

      verifyNever(() => mockProvider.reset());
    });
  });

  // -------------------------------------------------------------------------
  // resetForTesting
  // -------------------------------------------------------------------------

  group('resetForTesting()', () {
    test('restores enabled to true', () async {
      await tracker.configure([mockProvider]);
      tracker.enabled = false;
      tracker.resetForTesting();

      expect(tracker.enabled, isTrue);
    });

    test('restores unconfigured state so logEvent is a no-op', () async {
      await tracker.configure([mockProvider]);
      tracker.resetForTesting();

      await tracker.logEvent(AnalyticsEvent(name: 'after_reset'));

      verifyNever(() => mockProvider.logEvent(any()));
    });
  });
}
