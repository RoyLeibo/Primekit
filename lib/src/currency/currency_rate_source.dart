/// Contract for fetching currency exchange rates.
///
/// Implement this interface to provide rates from any backend
/// (HTTP API, Firestore, local database, etc.).
abstract interface class CurrencyRateSource {
  /// Fetches exchange rates for the given [base] currency.
  ///
  /// Returns a map of currency codes to their exchange rates relative to
  /// [base]. For example, if [base] is `'USD'`, the map might contain
  /// `{'EUR': 0.92, 'GBP': 0.79, ...}`.
  Future<Map<String, double>> fetchRates(String base);
}
