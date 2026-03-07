import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:primekit/currency.dart';

/// Firestore-backed [CurrencyRateSource] that reads exchange rates from a
/// Firestore collection and falls back to the HTTP API on failure.
///
/// Expects Firestore structure:
/// ```
/// exchange_rates/{base} → { rates: { EUR: 0.92, GBP: 0.79, ... } }
/// ```
class FirestoreCurrencyRateSource implements CurrencyRateSource {
  FirestoreCurrencyRateSource({
    FirebaseFirestore? firestore,
    CurrencyRateSource? fallback,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _fallback = fallback ?? HttpCurrencyRateSource();

  final FirebaseFirestore _firestore;
  final CurrencyRateSource _fallback;

  @override
  Future<Map<String, double>> fetchRates(String base) async {
    try {
      final doc = await _firestore.collection('exchange_rates').doc(base).get();

      if (!doc.exists || doc.data() == null) {
        return _fallback.fetchRates(base);
      }

      final data = doc.data()!;
      final rates = data['rates'] as Map<String, dynamic>?;

      if (rates == null || rates.isEmpty) {
        return _fallback.fetchRates(base);
      }

      return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return _fallback.fetchRates(base);
    }
  }
}
