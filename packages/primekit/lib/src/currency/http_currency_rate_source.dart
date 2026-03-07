import 'dart:convert';

import 'package:http/http.dart' as http;

import 'currency_rate_source.dart';

/// Fetches live exchange rates from the free open.er-api.com API.
///
/// No API key is required.
class HttpCurrencyRateSource implements CurrencyRateSource {
  HttpCurrencyRateSource({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  final http.Client _httpClient;

  @override
  Future<Map<String, double>> fetchRates(String base) async {
    final url = Uri.parse('$_baseUrl/$base');
    final response = await _httpClient
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch exchange rates: HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>?;

    if (rates == null) {
      throw Exception('No rates field in API response');
    }

    return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
}
