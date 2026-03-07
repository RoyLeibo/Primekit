import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Caches currency exchange rates in [SharedPreferences] with a configurable
/// time-to-live (TTL).
///
/// Rates are stored as JSON-encoded maps keyed by base currency.
class CurrencyCache {
  CurrencyCache({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _ratesPrefix = 'pk_currency_rates_';
  static const String _timestampPrefix = 'pk_currency_ts_';
  static const Duration _defaultTtl = Duration(hours: 1);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Returns cached rates for [base], or `null` if not cached.
  Future<Map<String, double>?> getCache(String base) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_ratesPrefix$base');
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Stores [rates] for [base] with the current timestamp.
  Future<void> setCache(String base, Map<String, double> rates) async {
    final prefs = await _getPrefs();
    await prefs.setString('$_ratesPrefix$base', jsonEncode(rates));
    await prefs.setInt(
      '$_timestampPrefix$base',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns `true` if cached rates for [base] exist and are within [ttl].
  Future<bool> isFresh(String base, [Duration ttl = _defaultTtl]) async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getInt('$_timestampPrefix$base');
    if (timestamp == null) return false;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age < ttl.inMilliseconds;
  }

  /// Removes all cached currency data.
  Future<void> clear() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_ratesPrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
