import 'ai_provider.dart';

/// Thin singleton wrapper around an [AiProvider].
///
/// Configure once at app startup then call from anywhere:
/// ```dart
/// AiService.configure(OpenAiProvider(apiKey: myKey));
///
/// final reply = await AiService.instance.complete(
///   'Buy groceries tomorrow',
///   systemPrompt: 'You are a TODO parser. Return JSON only.',
/// );
/// ```
final class AiService {
  AiService._();

  static AiService? _instance;

  static AiService get instance {
    _instance ??= AiService._();
    return _instance!;
  }

  AiProvider? _provider;

  /// Sets the active [AiProvider]. Call once during app initialisation.
  static void configure(AiProvider provider) {
    instance._provider = provider;
  }

  /// Forwards to [AiProvider.complete]. Returns `null` when not configured.
  Future<String?> complete(
    String userMessage, {
    String? systemPrompt,
    String? model,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) {
    return _provider?.complete(
          userMessage,
          systemPrompt: systemPrompt,
          model: model,
          maxTokens: maxTokens,
          temperature: temperature,
        ) ??
        Future.value(null);
  }
}
