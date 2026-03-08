import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/analytics.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAnalyticsProvider extends Mock implements AnalyticsProvider {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _checkoutDef = FunnelDefinition(
  name: 'checkout',
  steps: ['cart', 'shipping', 'payment', 'confirmation'],
);

const _onboardingDef = FunnelDefinition(
  name: 'onboarding',
  steps: ['welcome', 'profile', 'complete'],
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FunnelTracker tracker;
  late MockAnalyticsProvider mockProvider;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent(name: 'fallback'));
  });

  setUp(() async {
    mockProvider = MockAnalyticsProvider();
    when(() => mockProvider.name).thenReturn('mock');
    when(() => mockProvider.initialize()).thenAnswer((_) async {});
    when(() => mockProvider.logEvent(any())).thenAnswer((_) async {});

    await EventTracker.instance.configure([mockProvider]);

    tracker = FunnelTracker.instance;
    tracker.resetForTesting();
  });

  tearDown(() {
    tracker.resetForTesting();
    EventTracker.instance.resetForTesting();
  });

  // -------------------------------------------------------------------------
  // FunnelDefinition
  // -------------------------------------------------------------------------

  group('FunnelDefinition', () {
    test('stores name and steps', () {
      expect(_checkoutDef.name, 'checkout');
      expect(_checkoutDef.steps, [
        'cart',
        'shipping',
        'payment',
        'confirmation',
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // registerFunnel
  // -------------------------------------------------------------------------

  group('registerFunnel()', () {
    test('registers a funnel definition', () {
      tracker.registerFunnel(_checkoutDef);
      // startFunnel succeeds for registered funnels (no warning / early return).
      tracker.startFunnel('checkout');
      expect(tracker.getState('checkout'), isNotNull);
    });

    test('re-registering replaces the definition', () {
      tracker.registerFunnel(_checkoutDef);
      tracker.registerFunnel(
        const FunnelDefinition(name: 'checkout', steps: ['step1', 'step2']),
      );
      tracker.startFunnel('checkout');
      tracker.completeStep('checkout', 'step1');
      tracker.completeStep('checkout', 'step2');
      expect(tracker.getState('checkout')?.status, FunnelStatus.completed);
    });
  });

  // -------------------------------------------------------------------------
  // startFunnel
  // -------------------------------------------------------------------------

  group('startFunnel()', () {
    setUp(() {
      tracker.registerFunnel(_checkoutDef);
    });

    test('creates a new funnel state with started status', () {
      tracker.startFunnel('checkout');

      final state = tracker.getState('checkout');
      expect(state, isNotNull);
      expect(state!.status, FunnelStatus.started);
      expect(state.completedSteps, isEmpty);
      expect(state.funnelName, 'checkout');
    });

    test('includes userId when provided', () {
      tracker.startFunnel('checkout', userId: 'user_42');

      expect(tracker.getState('checkout')?.userId, 'user_42');
    });

    test('state has null userId when not provided', () {
      tracker.startFunnel('checkout');
      expect(tracker.getState('checkout')?.userId, isNull);
    });

    test('emits funnel_started analytics event', () async {
      tracker.startFunnel('checkout');
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockProvider.logEvent(captureAny())).captured;
      final events = captured.cast<AnalyticsEvent>();
      expect(events.any((e) => e.name == 'funnel_started'), isTrue);
    });

    test('replaces existing session when called again', () {
      tracker.startFunnel('checkout', userId: 'first_user');
      tracker.startFunnel('checkout', userId: 'second_user');

      final state = tracker.getState('checkout');
      expect(state?.userId, 'second_user');
      expect(state?.completedSteps, isEmpty);
    });

    test('is a no-op for unregistered funnel', () {
      tracker.startFunnel('unknown_funnel');
      expect(tracker.getState('unknown_funnel'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // completeStep
  // -------------------------------------------------------------------------

  group('completeStep()', () {
    setUp(() {
      tracker.registerFunnel(_checkoutDef);
      tracker.startFunnel('checkout');
    });

    test('advances the funnel to inProgress after first step', () {
      tracker.completeStep('checkout', 'cart');

      final state = tracker.getState('checkout')!;
      expect(state.status, FunnelStatus.inProgress);
      expect(state.completedSteps, contains('cart'));
    });

    test('records completed step in completedSteps list', () {
      tracker.completeStep('checkout', 'cart');
      tracker.completeStep('checkout', 'shipping');

      final state = tracker.getState('checkout')!;
      expect(state.completedSteps, containsAll(['cart', 'shipping']));
    });

    test('transitions to completed when all steps are done', () {
      for (final step in _checkoutDef.steps) {
        tracker.completeStep('checkout', step);
      }

      final state = tracker.getState('checkout')!;
      expect(state.status, FunnelStatus.completed);
      expect(state.completedAt, isNotNull);
    });

    test('emits funnel_step_completed event', () async {
      tracker.completeStep('checkout', 'cart');
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockProvider.logEvent(captureAny())).captured;
      final events = captured.cast<AnalyticsEvent>();
      expect(events.any((e) => e.name == 'funnel_step_completed'), isTrue);
    });

    test('emits funnel_completed event when last step completes', () async {
      for (final step in _checkoutDef.steps) {
        tracker.completeStep('checkout', step);
      }
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockProvider.logEvent(captureAny())).captured;
      final events = captured.cast<AnalyticsEvent>();
      expect(events.any((e) => e.name == 'funnel_completed'), isTrue);
    });

    test('is a no-op when funnel not registered', () {
      tracker.completeStep('nonexistent', 'step1');
      // No exception; state remains absent.
      expect(tracker.getState('nonexistent'), isNull);
    });

    test('is a no-op when no active session exists', () {
      tracker.resetForTesting();
      tracker.registerFunnel(_checkoutDef);
      tracker.completeStep('checkout', 'cart');
      expect(tracker.getState('checkout'), isNull);
    });

    test('is a no-op when session is already completed', () {
      for (final step in _checkoutDef.steps) {
        tracker.completeStep('checkout', step);
      }
      // Attempt to complete another step on the finished funnel.
      tracker.completeStep('checkout', 'cart');
      // Status should remain completed.
      expect(tracker.getState('checkout')?.status, FunnelStatus.completed);
    });

    test('is a no-op when session is abandoned', () {
      tracker.completeStep('checkout', 'cart');
      tracker.abandonFunnel('checkout');
      tracker.completeStep('checkout', 'shipping');
      expect(tracker.getState('checkout')?.status, FunnelStatus.abandoned);
    });
  });

  // -------------------------------------------------------------------------
  // abandonFunnel
  // -------------------------------------------------------------------------

  group('abandonFunnel()', () {
    setUp(() {
      tracker.registerFunnel(_checkoutDef);
      tracker.startFunnel('checkout');
    });

    test('transitions status to abandoned', () {
      tracker.abandonFunnel('checkout');
      expect(tracker.getState('checkout')?.status, FunnelStatus.abandoned);
    });

    test('stores abandon reason', () {
      tracker.abandonFunnel('checkout', reason: 'payment_failed');
      expect(tracker.getState('checkout')?.abandonReason, 'payment_failed');
    });

    test('stores null reason when none provided', () {
      tracker.abandonFunnel('checkout');
      expect(tracker.getState('checkout')?.abandonReason, isNull);
    });

    test('emits funnel_abandoned analytics event', () async {
      tracker.abandonFunnel('checkout', reason: 'cancelled');
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockProvider.logEvent(captureAny())).captured;
      final events = captured.cast<AnalyticsEvent>();
      expect(events.any((e) => e.name == 'funnel_abandoned'), isTrue);
    });

    test('is a no-op when no active session', () {
      tracker.resetForTesting();
      tracker.registerFunnel(_checkoutDef);
      tracker.abandonFunnel('checkout'); // No session started.
      expect(tracker.getState('checkout'), isNull);
    });

    test('is a no-op when session already completed', () {
      for (final step in _checkoutDef.steps) {
        tracker.completeStep('checkout', step);
      }
      tracker.abandonFunnel('checkout');
      expect(tracker.getState('checkout')?.status, FunnelStatus.completed);
    });
  });

  // -------------------------------------------------------------------------
  // getState
  // -------------------------------------------------------------------------

  group('getState()', () {
    test('returns null for funnel that was never started', () {
      tracker.registerFunnel(_checkoutDef);
      expect(tracker.getState('checkout'), isNull);
    });

    test('returns state after funnel is started', () {
      tracker.registerFunnel(_checkoutDef);
      tracker.startFunnel('checkout');
      expect(tracker.getState('checkout'), isNotNull);
    });

    test('returns null for entirely unknown funnel', () {
      expect(tracker.getState('mystery_funnel'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Multiple concurrent funnels
  // -------------------------------------------------------------------------

  group('multiple concurrent funnels', () {
    test('tracks two funnels independently', () {
      tracker.registerFunnel(_checkoutDef);
      tracker.registerFunnel(_onboardingDef);

      tracker.startFunnel('checkout');
      tracker.startFunnel('onboarding');

      tracker.completeStep('checkout', 'cart');
      tracker.completeStep('onboarding', 'welcome');

      expect(tracker.getState('checkout')?.completedSteps, contains('cart'));
      expect(
        tracker.getState('onboarding')?.completedSteps,
        contains('welcome'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // FunnelState.copyWith
  // -------------------------------------------------------------------------

  group('FunnelState.copyWith()', () {
    test('replaces specified fields and preserves others', () {
      tracker.registerFunnel(
        const FunnelDefinition(name: 'copy_test', steps: ['a', 'b']),
      );
      tracker.startFunnel('copy_test', userId: 'u1');
      final state = tracker.getState('copy_test')!;

      final updated = state.copyWith(status: FunnelStatus.inProgress);

      expect(updated.status, FunnelStatus.inProgress);
      expect(updated.funnelName, state.funnelName);
      expect(updated.userId, state.userId);
    });
  });

  // -------------------------------------------------------------------------
  // resetForTesting
  // -------------------------------------------------------------------------

  group('resetForTesting()', () {
    test('clears all definitions and states', () {
      tracker.registerFunnel(_checkoutDef);
      tracker.startFunnel('checkout');
      tracker.resetForTesting();

      // After reset, startFunnel is a no-op because definition is gone.
      tracker.startFunnel('checkout');
      expect(tracker.getState('checkout'), isNull);
    });
  });
}
