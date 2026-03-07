import 'dart:convert';
import 'package:http/http.dart' as http;

/// Abstract interface for fetching live currency exchange rates.
///
/// ```dart
/// PkCurrencyFormatter.configureRates(ExchangeRateApiProvider(apiKey: '...'));
/// final rate = await PkCurrencyFormatter.getRate('USD', 'EUR');
/// ```
abstract class CurrencyRateProvider {
  /// Returns the exchange rate from [from] to [to].
  Future<double> getRate(String from, String to);

  /// Returns all rates relative to [base] currency.
  Future<Map<String, double>> getAllRates(String base);
}

/// A free-tier implementation using exchangerate-api.com.
///
/// Provides daily updated rates. No API key needed for limited use.
class ExchangeRateApiProvider implements CurrencyRateProvider {
  const ExchangeRateApiProvider({this.apiKey});

  final String? apiKey;

  String get _baseUrl => apiKey != null
      ? 'https://v6.exchangerate-api.com/v6/$apiKey/latest'
      : 'https://open.er-api.com/v6/latest';

  @override
  Future<double> getRate(String from, String to) async {
    final rates = await getAllRates(from);
    final rate = rates[to.toUpperCase()];
    if (rate == null) throw Exception('Rate not found: $from -> $to');
    return rate;
  }

  @override
  Future<Map<String, double>> getAllRates(String base) async {
    final res = await http.get(Uri.parse('$_baseUrl/${base.toUpperCase()}'));
    if (res.statusCode != 200) {
      throw Exception('ExchangeRateApi error: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>;
    return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}

/// An in-memory cached rate provider that wraps another provider.
///
/// ```dart
/// PkCurrencyFormatter.configureRates(
///   CachedRateProvider(
///     ExchangeRateApiProvider(),
///     ttl: Duration(hours: 1),
///   ),
/// );
/// ```
class CachedRateProvider implements CurrencyRateProvider {
  CachedRateProvider(this._inner, {this.ttl = const Duration(hours: 1)});

  final CurrencyRateProvider _inner;
  final Duration ttl;
  final Map<String, _CacheEntry<Map<String, double>>> _cache = {};

  @override
  Future<double> getRate(String from, String to) async {
    final rates = await getAllRates(from);
    return rates[to.toUpperCase()] ??
        (throw Exception('Rate not found: $from -> $to'));
  }

  @override
  Future<Map<String, double>> getAllRates(String base) async {
    final key = base.toUpperCase();
    final entry = _cache[key];
    if (entry != null && !entry.isExpired(ttl)) return entry.value;
    final fresh = await _inner.getAllRates(base);
    _cache[key] = _CacheEntry(fresh);
    return fresh;
  }

  void clearCache() => _cache.clear();
}

class _CacheEntry<T> {
  _CacheEntry(this.value) : _cachedAt = DateTime.now();
  final T value;
  final DateTime _cachedAt;
  bool isExpired(Duration ttl) => DateTime.now().difference(_cachedAt) > ttl;
}
