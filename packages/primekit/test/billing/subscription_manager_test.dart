import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/billing.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSubscriptionDataSource extends Mock
    implements SubscriptionDataSource {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionInfo _info(
  String productId, {
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? expiresAt,
}) => SubscriptionInfo(
  productId: productId,
  status: status,
  expiresAt: expiresAt,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSubscriptionDataSource mockDataSource;
  late SubscriptionManager manager;

  setUp(() {
    mockDataSource = MockSubscriptionDataSource();
    when(
      () => mockDataSource.fetchSubscription(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockDataSource.fetchAllSubscriptions(),
    ).thenAnswer((_) async => []);
    when(() => mockDataSource.refresh()).thenAnswer((_) async {});
    when(() => mockDataSource.restore()).thenAnswer((_) async => []);

    manager = SubscriptionManager(dataSource: mockDataSource);
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // getSubscription
  // -------------------------------------------------------------------------

  group('getSubscription()', () {
    test('returns null when data source has no record', () async {
      final result = await manager.getSubscription('pro_monthly');
      expect(result, isNull);
    });

    test('returns SubscriptionInfo from data source', () async {
      final info = _info('pro_monthly');
      when(
        () => mockDataSource.fetchSubscription('pro_monthly'),
      ).thenAnswer((_) async => info);

      final result = await manager.getSubscription('pro_monthly');
      expect(result, equals(info));
    });

    test(
      'returns cached value on second call without hitting data source again',
      () async {
        final info = _info('pro_monthly');
        when(
          () => mockDataSource.fetchSubscription('pro_monthly'),
        ).thenAnswer((_) async => info);

        await manager.getSubscription('pro_monthly');
        await manager.getSubscription('pro_monthly');

        verify(() => mockDataSource.fetchSubscription('pro_monthly')).called(1);
      },
    );

    test('rethrows data source exceptions', () async {
      when(
        () => mockDataSource.fetchSubscription(any()),
      ).thenThrow(Exception('network error'));

      expect(() => manager.getSubscription('pro_monthly'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // getActiveSubscriptions
  // -------------------------------------------------------------------------

  group('getActiveSubscriptions()', () {
    test('returns only active subscriptions', () async {
      final active = _info('pro_monthly', status: SubscriptionStatus.active);
      final expired = _info('pro_yearly', status: SubscriptionStatus.expired);

      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [active, expired]);

      final results = await manager.getActiveSubscriptions();

      expect(results, contains(active));
      expect(results, isNot(contains(expired)));
    });

    test('returns empty list when no subscriptions exist', () async {
      final results = await manager.getActiveSubscriptions();
      expect(results, isEmpty);
    });

    test('includes trialing subscriptions as active', () async {
      final trialing = _info(
        'pro_monthly',
        status: SubscriptionStatus.trialing,
      );
      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [trialing]);

      final results = await manager.getActiveSubscriptions();
      expect(results, contains(trialing));
    });

    test('includes cancelled subscription within billing period', () async {
      final future = DateTime.now().toUtc().add(const Duration(days: 10));
      final cancelled = SubscriptionInfo(
        productId: 'pro_monthly',
        status: SubscriptionStatus.cancelled,
        expiresAt: future,
      );
      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [cancelled]);

      final results = await manager.getActiveSubscriptions();
      expect(results, contains(cancelled));
    });
  });

  // -------------------------------------------------------------------------
  // refresh
  // -------------------------------------------------------------------------

  group('refresh()', () {
    test('calls data source refresh and fetchAllSubscriptions', () async {
      await manager.refresh();

      verify(() => mockDataSource.refresh()).called(1);
      verify(() => mockDataSource.fetchAllSubscriptions()).called(1);
    });

    test('updates cache with latest subscriptions', () async {
      final info = _info('pro_monthly');
      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [info]);

      await manager.refresh();

      final cached = await manager.getSubscription('pro_monthly');
      expect(cached, equals(info));
    });

    test('notifies listeners after refresh', () async {
      var notified = false;
      manager.addListener(() => notified = true);

      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [_info('pro_monthly')]);

      await manager.refresh();
      expect(notified, isTrue);
    });

    test('rethrows data source exceptions', () async {
      when(() => mockDataSource.refresh()).thenThrow(Exception('server error'));

      expect(() => manager.refresh(), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // restore
  // -------------------------------------------------------------------------

  group('restore()', () {
    test('calls data source restore', () async {
      await manager.restore();
      verify(() => mockDataSource.restore()).called(1);
    });

    test('updates cache with restored subscriptions', () async {
      final restored = _info('pro_yearly');
      when(() => mockDataSource.restore()).thenAnswer((_) async => [restored]);

      await manager.restore();

      final cached = await manager.getSubscription('pro_yearly');
      expect(cached, equals(restored));
    });

    test('notifies listeners after restore', () async {
      var notified = false;
      manager.addListener(() => notified = true);
      when(
        () => mockDataSource.restore(),
      ).thenAnswer((_) async => [_info('pro_monthly')]);

      await manager.restore();
      expect(notified, isTrue);
    });

    test('rethrows exceptions', () async {
      when(
        () => mockDataSource.restore(),
      ).thenThrow(Exception('restore failed'));
      expect(() => manager.restore(), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // hasPremium
  // -------------------------------------------------------------------------

  group('hasPremium', () {
    test('returns false when cache is empty', () {
      expect(manager.hasPremium, isFalse);
    });

    test('returns true after refresh with active subscription', () async {
      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [_info('pro_monthly')]);

      await manager.refresh();
      expect(manager.hasPremium, isTrue);
    });

    test('returns false when all subscriptions are expired', () async {
      when(() => mockDataSource.fetchAllSubscriptions()).thenAnswer(
        (_) async => [_info('pro_monthly', status: SubscriptionStatus.expired)],
      );

      await manager.refresh();
      expect(manager.hasPremium, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // subscriptionUpdates stream
  // -------------------------------------------------------------------------

  group('subscriptionUpdates stream', () {
    test('emits list after refresh', () async {
      final info = _info('pro_monthly');
      when(
        () => mockDataSource.fetchAllSubscriptions(),
      ).thenAnswer((_) async => [info]);

      final streamFuture =
          manager.subscriptionUpdates
              .skip(1) // skip seed value
              .first;

      await manager.refresh();
      final emitted = await streamFuture;
      expect(emitted, contains(info));
    });

    test('replays the latest value immediately to new subscribers', () async {
      // The BehaviorSubject should replay the seeded empty list.
      final emitted = <List<SubscriptionInfo>>[];
      final sub = manager.subscriptionUpdates.listen(emitted.add);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SubscriptionInfo.isActive
  // -------------------------------------------------------------------------

  group('SubscriptionInfo.isActive', () {
    test('active status returns true', () {
      expect(_info('p', status: SubscriptionStatus.active).isActive, isTrue);
    });

    test('trialing status returns true', () {
      expect(_info('p', status: SubscriptionStatus.trialing).isActive, isTrue);
    });

    test('expired status returns false', () {
      expect(_info('p', status: SubscriptionStatus.expired).isActive, isFalse);
    });

    test('paused status returns false', () {
      expect(_info('p', status: SubscriptionStatus.paused).isActive, isFalse);
    });

    test('unknown status returns false', () {
      expect(_info('p', status: SubscriptionStatus.unknown).isActive, isFalse);
    });

    test('cancelled with future expiry returns true', () {
      final future = DateTime.now().toUtc().add(const Duration(days: 5));
      final info = SubscriptionInfo(
        productId: 'p',
        status: SubscriptionStatus.cancelled,
        expiresAt: future,
      );
      expect(info.isActive, isTrue);
    });

    test('cancelled with past expiry returns false', () {
      final past = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final info = SubscriptionInfo(
        productId: 'p',
        status: SubscriptionStatus.cancelled,
        expiresAt: past,
      );
      expect(info.isActive, isFalse);
    });

    test('cancelled with null expiry returns false', () {
      final info = SubscriptionInfo(
        productId: 'p',
        status: SubscriptionStatus.cancelled,
      );
      expect(info.isActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SubscriptionInfo.daysUntilExpiry
  // -------------------------------------------------------------------------

  group('SubscriptionInfo.daysUntilExpiry', () {
    test('returns null when expiresAt is null', () {
      expect(_info('p').daysUntilExpiry, isNull);
    });

    test('returns positive duration when expiry is in the future', () {
      final future = DateTime.now().toUtc().add(const Duration(days: 10));
      final info = SubscriptionInfo(
        productId: 'p',
        status: SubscriptionStatus.active,
        expiresAt: future,
      );
      expect(info.daysUntilExpiry, isNotNull);
      expect(info.daysUntilExpiry!.inDays, greaterThan(0));
    });

    test('returns null when subscription has already expired', () {
      final past = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final info = SubscriptionInfo(
        productId: 'p',
        status: SubscriptionStatus.expired,
        expiresAt: past,
      );
      expect(info.daysUntilExpiry, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // SubscriptionInfo.copyWith
  // -------------------------------------------------------------------------

  group('SubscriptionInfo.copyWith()', () {
    test('replaces specified fields', () {
      final original = _info('pro_monthly');
      final copy = original.copyWith(status: SubscriptionStatus.expired);

      expect(copy.productId, original.productId);
      expect(copy.status, SubscriptionStatus.expired);
    });

    test('preserves unspecified fields', () {
      final original = SubscriptionInfo(
        productId: 'pro',
        status: SubscriptionStatus.active,
        isInTrial: true,
        willRenew: true,
      );
      final copy = original.copyWith(status: SubscriptionStatus.cancelled);

      expect(copy.isInTrial, isTrue);
      expect(copy.willRenew, isTrue);
    });
  });
}
