import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';

/// [AiProvider] backed by the Anthropic Messages API.
///
/// Pass an empty [apiKey] to silently disable AI features without crashing.
///
/// ```dart
/// final provider = AnthropicProvider(
///   apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: ''),
/// );
/// ```
final class AnthropicProvider implements AiProvider {
  AnthropicProvider({
    required this.apiKey,
    this.defaultModel = 'claude-haiku-4-5-20251001',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final String defaultModel;
  final http.Client _httpClient;

  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _anthropicVersion = '2023-06-01';

  @override
  Future<String?> complete(
    String userMessage, {
    String? systemPrompt,
    String? model,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    if (apiKey.isEmpty) return null;

    try {
      final body = <String, dynamic>{
        'model': model ?? defaultModel,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      };
      if (systemPrompt != null) body['system'] = systemPrompt;

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': _anthropicVersion,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[AnthropicProvider] API error ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List?;
      return content?.first['text'] as String?;
    } catch (e) {
      debugPrint('[AnthropicProvider] complete error: $e');
      return null;
    }
  }
}
