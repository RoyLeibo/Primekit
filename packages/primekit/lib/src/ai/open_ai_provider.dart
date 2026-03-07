import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';

/// [AiProvider] backed by the OpenAI Chat Completions API.
///
/// Pass an empty [apiKey] to silently disable AI features without crashing.
///
/// ```dart
/// final provider = OpenAiProvider(
///   apiKey: const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
/// );
/// ```
final class OpenAiProvider implements AiProvider {
  OpenAiProvider({
    required this.apiKey,
    this.defaultModel = 'gpt-4o-mini',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final String defaultModel;
  final http.Client _httpClient;

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  @override
  Future<String?> complete(
    String userMessage, {
    String? systemPrompt,
    String? model,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    if (apiKey.isEmpty) return null;

    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model ?? defaultModel,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[OpenAiProvider] API error ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['choices'] as List).first['message']['content'] as String?;
    } catch (e) {
      debugPrint('[OpenAiProvider] complete error: $e');
      return null;
    }
  }
}
