import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/billing.dart';
import 'package:primekit/core.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSubscriptionDataSource extends Mock
    implements SubscriptionDataSource {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionInfo _activeInfo(String productId) =>
    SubscriptionInfo(productId: productId, status: SubscriptionStatus.active);

SubscriptionInfo _expiredInfo(String productId) =>
    SubscriptionInfo(productId: productId, status: SubscriptionStatus.expired);

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

    // Reset any previously configured singleton.
    EntitlementChecker.reset();
  });

  tearDown(() {
    EntitlementChecker.reset();
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // configure / instance
  // -------------------------------------------------------------------------

  group('configure() / instance', () {
    test('throws ConfigurationException before configure()', () {
      expect(
        () => EntitlementChecker.instance,
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('isConfigured returns false before configure()', () {
      expect(EntitlementChecker.isConfigured, isFalse);
    });

    test('isConfigured returns true after configure()', () {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'export_pdf': ['pro'],
        },
      );
      expect(EntitlementChecker.isConfigured, isTrue);
    });

    test('instance is available after configure()', () {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {},
      );
      expect(() => EntitlementChecker.instance, returnsNormally);
    });

    test('calling configure() again overwrites previous config', () {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'old_feature': ['old_product'],
        },
      );
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'new_feature': ['new_product'],
        },
      );
      final products = EntitlementChecker.instance.productsForFeature(
        'new_feature',
      );
      expect(products, contains('new_product'));
    });
  });

  // -------------------------------------------------------------------------
  // check()
  // -------------------------------------------------------------------------

  group('check()', () {
    setUp(() {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'export_pdf': ['pro_monthly', 'pro_yearly'],
          'priority_chat': ['enterprise'],
        },
      );
    });

    test('returns EntitlementAllowed when product is active', () async {
      when(
        () => mockDataSource.fetchSubscription('pro_monthly'),
      ).thenAnswer((_) async => _activeInfo('pro_monthly'));

      final result = await EntitlementChecker.instance.check('export_pdf');

      expect(result, isA<EntitlementAllowed>());
      expect((result as EntitlementAllowed).productId, 'pro_monthly');
    });

    test('returns EntitlementAllowed for second product in list', () async {
      when(
        () => mockDataSource.fetchSubscription('pro_monthly'),
      ).thenAnswer((_) async => _expiredInfo('pro_monthly'));
      when(
        () => mockDataSource.fetchSubscription('pro_yearly'),
      ).thenAnswer((_) async => _activeInfo('pro_yearly'));

      final result = await EntitlementChecker.instance.check('export_pdf');

      expect(result, isA<EntitlementAllowed>());
      expect((result as EntitlementAllowed).productId, 'pro_yearly');
    });

    test('returns EntitlementDenied when no product is active', () async {
      when(
        () => mockDataSource.fetchSubscription(any()),
      ).thenAnswer((_) async => _expiredInfo('pro_monthly'));

      final result = await EntitlementChecker.instance.check('export_pdf');

      expect(result, isA<EntitlementDenied>());
    });

    test('returns EntitlementDenied for unknown feature', () async {
      final result = await EntitlementChecker.instance.check(
        'nonexistent_feature',
      );
      expect(result, isA<EntitlementDenied>());
    });

    test('returns EntitlementDenied when product not found (null)', () async {
      when(
        () => mockDataSource.fetchSubscription(any()),
      ).thenAnswer((_) async => null);

      final result = await EntitlementChecker.instance.check('export_pdf');
      expect(result, isA<EntitlementDenied>());
    });

    test('returns EntitlementLoading on data source exception', () async {
      when(
        () => mockDataSource.fetchSubscription(any()),
      ).thenThrow(Exception('network error'));

      final result = await EntitlementChecker.instance.check('export_pdf');
      expect(result, isA<EntitlementLoading>());
    });
  });

  // -------------------------------------------------------------------------
  // canAccess()
  // -------------------------------------------------------------------------

  group('canAccess()', () {
    setUp(() {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'dark_theme': ['pro_monthly'],
        },
      );
    });

    test('returns true when active subscription exists', () async {
      when(
        () => mockDataSource.fetchSubscription('pro_monthly'),
      ).thenAnswer((_) async => _activeInfo('pro_monthly'));

      expect(await EntitlementChecker.instance.canAccess('dark_theme'), isTrue);
    });

    test('returns false when no active subscription', () async {
      when(
        () => mockDataSource.fetchSubscription(any()),
      ).thenAnswer((_) async => null);

      expect(
        await EntitlementChecker.instance.canAccess('dark_theme'),
        isFalse,
      );
    });

    test('returns false for unknown feature', () async {
      expect(await EntitlementChecker.instance.canAccess('unknown'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // accessibleFeatures()
  // -------------------------------------------------------------------------

  group('accessibleFeatures()', () {
    setUp(() {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'export_pdf': ['pro_monthly'],
          'dark_theme': ['pro_monthly'],
          'sso': ['enterprise'],
        },
      );
    });

    test('returns only features with active subscriptions', () async {
      when(
        () => mockDataSource.fetchSubscription('pro_monthly'),
      ).thenAnswer((_) async => _activeInfo('pro_monthly'));
      when(
        () => mockDataSource.fetchSubscription('enterprise'),
      ).thenAnswer((_) async => null);

      final features = await EntitlementChecker.instance.accessibleFeatures();

      expect(features, containsAll(['export_pdf', 'dark_theme']));
      expect(features, isNot(contains('sso')));
    });

    test('returns empty list when no subscriptions active', () async {
      when(
        () => mockDataSource.fetchSubscription(any()),
      ).thenAnswer((_) async => null);

      final features = await EntitlementChecker.instance.accessibleFeatures();
      expect(features, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // blockedFeatures()
  // -------------------------------------------------------------------------

  group('blockedFeatures()', () {
    setUp(() {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'export_pdf': ['pro_monthly'],
          'sso': ['enterprise'],
        },
      );
    });

    test('returns features whose subscriptions are not active', () async {
      when(
        () => mockDataSource.fetchSubscription('pro_monthly'),
      ).thenAnswer((_) async => _activeInfo('pro_monthly'));
      when(
        () => mockDataSource.fetchSubscription('enterprise'),
      ).thenAnswer((_) async => null);

      final blocked = await EntitlementChecker.instance.blockedFeatures();

      expect(blocked, contains('sso'));
      expect(blocked, isNot(contains('export_pdf')));
    });
  });

  // -------------------------------------------------------------------------
  // productsForFeature()
  // -------------------------------------------------------------------------

  group('productsForFeature()', () {
    setUp(() {
      EntitlementChecker.configure(
        subscriptionManager: manager,
        featureToProductMap: {
          'export_pdf': ['pro_monthly', 'pro_yearly'],
        },
      );
    });

    test('returns the product ids for a known feature', () {
      final products = EntitlementChecker.instance.productsForFeature(
        'export_pdf',
      );
      expect(products, containsAll(['pro_monthly', 'pro_yearly']));
    });

    test('returns empty list for unknown feature', () {
      final products = EntitlementChecker.instance.productsForFeature(
        'unknown',
      );
      expect(products, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // EntitlementResult helpers
  // -------------------------------------------------------------------------

  group('EntitlementResult.isAllowed', () {
    test('EntitlementAllowed.isAllowed is true', () {
      const result = EntitlementAllowed(productId: 'pro');
      expect(result.isAllowed, isTrue);
    });

    test('EntitlementDenied.isAllowed is false', () {
      const result = EntitlementDenied(reason: 'no sub');
      expect(result.isAllowed, isFalse);
    });

    test('EntitlementLoading.isAllowed is false', () {
      const result = EntitlementLoading();
      expect(result.isAllowed, isFalse);
    });
  });
}
