import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'email_message.dart';
import 'email_provider.dart';

/// The central email sending service.
///
/// [EmailService] is a singleton that wraps any [EmailProvider] and exposes
/// a simple [send] method. Configure it once at startup:
///
/// ```dart
/// EmailService.instance.configure(
///   provider: SendGridProvider(
///     apiKey: Env.sendgridApiKey,
///     fromEmail: 'noreply@example.com',
///   ),
/// );
///
/// // Later:
/// final result = await EmailService.instance.send(
///   EmailMessage(
///     to: 'user@example.com',
///     subject: 'Hello!',
///     htmlBody: '<p>Welcome aboard.</p>',
///   ),
/// );
/// ```
class EmailService {
  EmailService._();

  static final EmailService _instance = EmailService._();

  /// The shared singleton instance.
  static EmailService get instance => _instance;

  EmailProvider? _provider;
  static const String _tag = 'EmailService';

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the service with the given [provider].
  ///
  /// Must be called before [send]. Safe to call again to swap providers.
  void configure({required EmailProvider provider}) {
    _provider = provider;
    PrimekitLogger.info(
      'EmailService configured with provider: ${provider.name}',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------------

  /// Sends [message] using the configured provider.
  ///
  /// Throws [ConfigurationException] if [configure] has not been called.
  ///
  /// Returns an [EmailResult]; never throws on provider-level errors — those
  /// are captured in [EmailFailure].
  Future<EmailResult> send(EmailMessage message) async {
    final provider = _provider;
    if (provider == null) {
      throw const ConfigurationException(
        message:
            'EmailService is not configured. Call EmailService.instance.configure() '
            'with a provider before calling send().',
      );
    }

    PrimekitLogger.debug(
      'Sending email to ${message.to} via ${provider.name}.',
      tag: _tag,
    );

    final result = await provider.send(message);

    result.when(
      success: (r) => PrimekitLogger.info(
        'Email delivered. messageId=${r.messageId}',
        tag: _tag,
      ),
      failure: (r) => PrimekitLogger.warning(
        'Email delivery failed: ${r.reason} (status=${r.statusCode})',
        tag: _tag,
      ),
    );

    return result;
  }

  /// Returns `true` if [configure] has been called.
  bool get isConfigured => _provider != null;

  /// The name of the active provider, or `null` if not configured.
  String? get providerName => _provider?.name;

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the service to its unconfigured state.
  ///
  /// For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _provider = null;
  }
}
