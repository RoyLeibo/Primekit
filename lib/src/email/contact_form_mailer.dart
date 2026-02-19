import '../core/logger.dart';
import 'email_message.dart';
import 'email_service.dart';

/// A drop-in contact form email sender with retry logic and HTML formatting.
///
/// Wrap it around [EmailService] to send well-formatted contact form
/// submissions without building templates manually:
///
/// ```dart
/// final mailer = ContactFormMailer(
///   toEmail: 'support@myapp.com',
///   subject: 'New Contact Request',
/// );
///
/// final result = await mailer.send(
///   senderName: 'Alice',
///   senderEmail: 'alice@example.com',
///   message: 'Hello, I have a question about your pricing.',
///   additionalFields: {'Phone': '+1-555-0100'},
/// );
/// ```
class ContactFormMailer {
  /// Creates a contact form mailer.
  ///
  /// [toEmail] is the destination inbox for submissions.
  /// [subject] customises the subject line.
  /// [fromEmail] overrides the reply-to address shown to recipients (optional).
  /// [maxRetries] controls how many send attempts are made (default 3).
  ContactFormMailer({
    required String toEmail,
    String subject = 'New Contact Form Submission',
    String? fromEmail,
    int maxRetries = 3,
  })  : _toEmail = toEmail,
        _subject = subject,
        _fromEmail = fromEmail,
        _maxRetries = maxRetries.clamp(1, 10);

  final String _toEmail;
  final String _subject;
  final String? _fromEmail;
  final int _maxRetries;

  static const String _tag = 'ContactFormMailer';

  // Delays between retry attempts: 1s, 3s, 5s
  static const List<Duration> _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sends a contact form submission.
  ///
  /// Formats a clean HTML email and retries up to [maxRetries] times on
  /// transient failures before returning the final [EmailResult].
  ///
  /// [senderName] and [senderEmail] identify the person submitting the form.
  /// [message] is the body text they wrote.
  /// [additionalFields] adds extra labelled rows to the email (e.g. phone, company).
  Future<EmailResult> send({
    required String senderName,
    required String senderEmail,
    required String message,
    Map<String, String>? additionalFields,
  }) async {
    final emailMessage = EmailMessage(
      to: _toEmail,
      subject: _subject,
      replyTo: _fromEmail ?? senderEmail,
      textBody: _buildTextBody(
        senderName: senderName,
        senderEmail: senderEmail,
        message: message,
        additionalFields: additionalFields,
      ),
      htmlBody: _buildHtmlBody(
        senderName: senderName,
        senderEmail: senderEmail,
        message: message,
        additionalFields: additionalFields,
      ),
    );

    EmailResult? lastResult;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      PrimekitLogger.debug(
        'ContactFormMailer attempt $attempt/$_maxRetries',
        tag: _tag,
      );

      lastResult = await EmailService.instance.send(emailMessage);

      if (lastResult.isSuccess) {
        PrimekitLogger.info(
          'Contact form email sent on attempt $attempt.',
          tag: _tag,
        );
        return lastResult;
      }

      final failure = lastResult as EmailFailure;

      // Don't retry on client errors (4xx) — they won't self-resolve.
      final statusCode = failure.statusCode;
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        PrimekitLogger.warning(
          'ContactFormMailer: non-retryable error ($statusCode). Giving up.',
          tag: _tag,
        );
        return lastResult;
      }

      if (attempt < _maxRetries) {
        final delay = attempt <= _retryDelays.length
            ? _retryDelays[attempt - 1]
            : const Duration(seconds: 5);
        PrimekitLogger.warning(
          'ContactFormMailer attempt $attempt failed: ${failure.reason}. '
          'Retrying in ${delay.inSeconds}s.',
          tag: _tag,
        );
        await Future<void>.delayed(delay);
      }
    }

    PrimekitLogger.error(
      'ContactFormMailer: all $_maxRetries attempts failed.',
      tag: _tag,
    );
    return lastResult!;
  }

  // ---------------------------------------------------------------------------
  // Template helpers
  // ---------------------------------------------------------------------------

  String _buildTextBody({
    required String senderName,
    required String senderEmail,
    required String message,
    Map<String, String>? additionalFields,
  }) {
    final buffer = StringBuffer()
      ..writeln('New Contact Form Submission')
      ..writeln('=' * 40)
      ..writeln()
      ..writeln('From: $senderName <$senderEmail>')
      ..writeln('Message:')
      ..writeln(message);

    if (additionalFields != null && additionalFields.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Additional Information:');
      for (final entry in additionalFields.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  String _buildHtmlBody({
    required String senderName,
    required String senderEmail,
    required String message,
    Map<String, String>? additionalFields,
  }) {
    final escapedMessage = _escapeHtml(message);
    final escapedName = _escapeHtml(senderName);
    final escapedEmail = _escapeHtml(senderEmail);

    final additionalRows = StringBuffer();
    if (additionalFields != null && additionalFields.isNotEmpty) {
      additionalRows.write('''
        <tr>
          <td colspan="2" style="padding:16px 24px 8px;font-size:13px;
            font-weight:600;color:#6b7280;text-transform:uppercase;
            letter-spacing:0.05em;border-top:1px solid #f3f4f6;">
            Additional Information
          </td>
        </tr>
      ''');
      for (final entry in additionalFields.entries) {
        final key = _escapeHtml(entry.key);
        final value = _escapeHtml(entry.value);
        additionalRows.write('''
          <tr>
            <td style="padding:6px 24px;font-size:14px;color:#6b7280;
              width:140px;vertical-align:top;white-space:nowrap;">$key</td>
            <td style="padding:6px 24px;font-size:14px;color:#111827;">$value</td>
          </tr>
        ''');
      }
    }

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>Contact Form Submission</title>
</head>
<body style="margin:0;padding:0;background-color:#f9fafb;font-family:
  -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0"
    style="background:#f9fafb;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0"
          style="max-width:600px;background:#ffffff;border-radius:12px;
          box-shadow:0 1px 3px rgba(0,0,0,0.1);overflow:hidden;">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#667eea,#764ba2);
              padding:28px 24px;">
              <h1 style="margin:0;font-size:22px;font-weight:700;
                color:#ffffff;letter-spacing:-0.5px;">
                New Contact Form Submission
              </h1>
            </td>
          </tr>

          <!-- Sender info -->
          <tr>
            <td>
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding:20px 24px 6px;font-size:13px;
                    font-weight:600;color:#6b7280;text-transform:uppercase;
                    letter-spacing:0.05em;">Sender</td>
                </tr>
                <tr>
                  <td style="padding:4px 24px 20px;">
                    <span style="font-size:16px;font-weight:600;
                      color:#111827;">$escapedName</span>
                    <span style="font-size:14px;color:#6b7280;
                      margin-left:8px;">&lt;<a href="mailto:$escapedEmail"
                      style="color:#667eea;text-decoration:none;">$escapedEmail</a>&gt;
                    </span>
                  </td>
                </tr>

                <!-- Divider -->
                <tr>
                  <td style="padding:0 24px;">
                    <hr style="border:none;border-top:1px solid #f3f4f6;
                      margin:0;">
                  </td>
                </tr>

                <!-- Message -->
                <tr>
                  <td style="padding:16px 24px 8px;font-size:13px;
                    font-weight:600;color:#6b7280;text-transform:uppercase;
                    letter-spacing:0.05em;">Message</td>
                </tr>
                <tr>
                  <td style="padding:4px 24px 24px;">
                    <p style="margin:0;font-size:15px;line-height:1.6;
                      color:#374151;white-space:pre-wrap;">$escapedMessage</p>
                  </td>
                </tr>

                ${additionalRows.toString()}
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:16px 24px;background:#f9fafb;
              border-top:1px solid #e5e7eb;">
              <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;">
                This email was sent automatically from your contact form.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  static String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
}
