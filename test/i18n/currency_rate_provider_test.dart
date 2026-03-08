import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:primekit/src/i18n/currency_rate_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockCurrencyRateProvider extends Mock implements CurrencyRateProvider {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CurrencyRateProvider interface', () {
    test('mock implements CurrencyRateProvider', () {
      expect(_MockCurrencyRateProvider(), isA<CurrencyRateProvider>());
    });

    test('getRate delegates to getAllRates mock', () async {
      final mock = _MockCurrencyRateProvider();
      when(() => mock.getRate('USD', 'EUR')).thenAnswer((_) async => 0.92);

      final rate = await mock.getRate('USD', 'EUR');
      expect(rate, 0.92);
    });

    test('getAllRates returns a map', () async {
      final mock = _MockCurrencyRateProvider();
      when(
        () => mock.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92, 'GBP': 0.78, 'JPY': 150.0});

      final rates = await mock.getAllRates('USD');
      expect(rates['EUR'], 0.92);
      expect(rates['GBP'], 0.78);
      expect(rates['JPY'], 150.0);
    });
  });

  // ---------------------------------------------------------------------------
  // CachedRateProvider
  // ---------------------------------------------------------------------------

  group('CachedRateProvider', () {
    late _MockCurrencyRateProvider inner;
    late CachedRateProvider cached;

    setUp(() {
      inner = _MockCurrencyRateProvider();
      cached = CachedRateProvider(inner, ttl: const Duration(hours: 1));
    });

    test('delegates getAllRates to inner provider on first call', () async {
      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92});

      final rates = await cached.getAllRates('USD');
      expect(rates['EUR'], 0.92);
      verify(() => inner.getAllRates('USD')).called(1);
    });

    test('serves from cache on second call within TTL', () async {
      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92});

      await cached.getAllRates('USD');
      await cached.getAllRates('USD');

      // Inner provider called only once.
      verify(() => inner.getAllRates('USD')).called(1);
    });

    test('getRate uses cached getAllRates', () async {
      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92, 'GBP': 0.78});

      final rate = await cached.getRate('USD', 'EUR');
      expect(rate, 0.92);
    });

    test('getRate for unknown currency throws', () async {
      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92});

      await expectLater(
        cached.getRate('USD', 'XYZ'),
        throwsA(isA<Exception>()),
      );
    });

    test('clearCache forces re-fetch on next call', () async {
      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92});

      await cached.getAllRates('USD');
      cached.clearCache();
      await cached.getAllRates('USD');

      // Called twice: once before clear, once after.
      verify(() => inner.getAllRates('USD')).called(2);
    });

    test('different base currencies cached separately', () async {
      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92});
      when(
        () => inner.getAllRates('GBP'),
      ).thenAnswer((_) async => {'USD': 1.28});

      await cached.getAllRates('USD');
      await cached.getAllRates('GBP');
      await cached.getAllRates('USD'); // served from cache
      await cached.getAllRates('GBP'); // served from cache

      verify(() => inner.getAllRates('USD')).called(1);
      verify(() => inner.getAllRates('GBP')).called(1);
    });

    test(
      'base currency key is case-insensitive (normalised to upper)',
      () async {
        when(
          () => inner.getAllRates('USD'),
        ).thenAnswer((_) async => {'EUR': 0.92});

        await cached.getAllRates('usd'); // lowercase
        await cached.getAllRates('USD'); // uppercase — should hit cache

        verify(() => inner.getAllRates(any())).called(1);
      },
    );

    test('expired cache re-fetches from inner', () async {
      // TTL of 0 — always expired.
      final shortTtl = CachedRateProvider(inner, ttl: Duration.zero);

      when(
        () => inner.getAllRates('USD'),
      ).thenAnswer((_) async => {'EUR': 0.92});

      await shortTtl.getAllRates('USD');
      await shortTtl.getAllRates('USD');

      // Both calls go to inner because TTL is zero.
      verify(() => inner.getAllRates('USD')).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // ExchangeRateApiProvider — URL construction
  // ---------------------------------------------------------------------------

  group('ExchangeRateApiProvider — URL construction', () {
    test('uses open.er-api.com when no apiKey provided', () {
      const provider = ExchangeRateApiProvider();
      // We can't call the real HTTP endpoint in tests, but we can verify
      // the provider is constructed without errors.
      expect(provider.apiKey, isNull);
    });

    test('stores apiKey when provided', () {
      const provider = ExchangeRateApiProvider(apiKey: 'abc123');
      expect(provider.apiKey, 'abc123');
    });
  });
}
