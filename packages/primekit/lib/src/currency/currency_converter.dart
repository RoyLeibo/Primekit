import 'currency_cache.dart';
import 'currency_rate_source.dart';

/// Singleton currency converter that fetches, caches, and converts between
/// currencies.
///
/// Must be configured once via [configure] before accessing [instance].
///
/// ```dart
/// CurrencyConverter.configure(
///   HttpCurrencyRateSource(),
///   cache: CurrencyCache(),
/// );
///
/// final usd = await CurrencyConverter.instance.convert(
///   100,
///   from: 'EUR',
///   to: 'USD',
/// );
/// ```
class CurrencyConverter {
  CurrencyConverter._({
    required CurrencyRateSource source,
    CurrencyCache? cache,
  }) : _source = source,
       _cache = cache;

  static CurrencyConverter? _instance;

  final CurrencyRateSource _source;
  final CurrencyCache? _cache;

  DateTime? _lastFetchTime;

  /// Configures and returns the singleton [CurrencyConverter].
  ///
  /// Subsequent calls replace the existing instance.
  static CurrencyConverter configure(
    CurrencyRateSource source, {
    CurrencyCache? cache,
  }) {
    _instance = CurrencyConverter._(source: source, cache: cache);
    return _instance!;
  }

  /// Returns the configured singleton instance.
  ///
  /// Throws [StateError] if [configure] has not been called.
  static CurrencyConverter get instance {
    if (_instance == null) {
      throw StateError(
        'CurrencyConverter not configured. Call CurrencyConverter.configure() first.',
      );
    }
    return _instance!;
  }

  /// Converts [amount] from currency [from] to currency [to].
  Future<double> convert(
    double amount, {
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    final rates = await getRates(from);
    final rate = rates[to];
    if (rate == null) {
      throw Exception('No exchange rate found for $to (base: $from)');
    }
    return amount * rate;
  }

  /// Returns all exchange rates for [baseCurrency].
  ///
  /// Uses cache if available and fresh; otherwise fetches from the source.
  Future<Map<String, double>> getRates(String baseCurrency) async {
    if (_cache != null && await _cache.isFresh(baseCurrency)) {
      final cached = await _cache.getCache(baseCurrency);
      if (cached != null) return cached;
    }

    final rates = await _source.fetchRates(baseCurrency);
    _lastFetchTime = DateTime.now();

    if (_cache != null) {
      await _cache.setCache(baseCurrency, rates);
    }

    return rates;
  }

  /// Forces a refresh by clearing the cache.
  Future<void> refresh() async {
    await _cache?.clear();
  }

  /// Returns `true` if the last fetch was more than 1 hour ago or never
  /// happened.
  bool get isStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) >
        const Duration(hours: 1);
  }
}
