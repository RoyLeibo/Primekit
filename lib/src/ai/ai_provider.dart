/// Abstract interface for AI language model providers.
///
/// Implement this to add a new provider (OpenAI, Anthropic, Gemini, etc.)
/// and inject it into [AiService].
abstract interface class AiProvider {
  /// Sends [userMessage] to the model and returns the response text.
  ///
  /// [systemPrompt] sets the model's behaviour/persona for the session.
  /// [model] overrides the provider's default model.
  /// [maxTokens] caps the response length.
  /// [temperature] controls randomness (0 = deterministic, 1 = creative).
  ///
  /// Returns `null` when the provider is unconfigured (no API key) or on
  /// any unrecoverable error. Callers should handle `null` gracefully.
  Future<String?> complete(
    String userMessage, {
    String? systemPrompt,
    String? model,
    int maxTokens = 1000,
    double temperature = 0.7,
  });
}
