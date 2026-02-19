import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'email_message.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// The common interface all email providers must implement.
///
/// Implement this to add a custom email provider:
///
/// ```dart
/// class MailgunProvider implements EmailProvider {
///   @override
///   String get name => 'Mailgun';
///
///   @override
///   Future<EmailResult> send(EmailMessage message) async { ... }
/// }
/// ```
abstract class EmailProvider {
  const EmailProvider();

  /// The human-readable provider name (e.g. `'SendGrid'`).
  String get name;

  /// Sends [message] and returns an [EmailResult].
  ///
  /// Never throws; errors are encapsulated in [EmailFailure].
  Future<EmailResult> send(EmailMessage message);
}

// ---------------------------------------------------------------------------
// SendGrid
// ---------------------------------------------------------------------------

/// Sends emails via the [SendGrid v3 Mail Send API](https://docs.sendgrid.com/api-reference/mail-send/mail-send).
///
/// **Required dependency:** `dio` (already in pubspec).
///
/// ```dart
/// EmailService.instance.configure(
///   provider: SendGridProvider(
///     apiKey: Env.sendgridApiKey,
///     fromEmail: 'noreply@example.com',
///     fromName: 'My App',
///   ),
/// );
/// ```
class SendGridProvider implements EmailProvider {
  /// Creates a SendGrid email provider.
  const SendGridProvider({
    required String apiKey,
    required String fromEmail,
    String? fromName,
  })  : _apiKey = apiKey,
        _fromEmail = fromEmail,
        _fromName = fromName;

  final String _apiKey;
  final String _fromEmail;
  final String? _fromName;

  static const String _endpoint =
      'https://api.sendgrid.com/v3/mail/send';
  static const String _tag = 'SendGridProvider';

  @override
  String get name => 'SendGrid';

  @override
  Future<EmailResult> send(EmailMessage message) async {
    final dio = Dio();

    try {
      final body = _buildPayload(message);

      final response = await dio.post<void>(
        _endpoint,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode == 202) {
        // SendGrid returns 202 Accepted with no message ID in the body;
        // the message ID is in the X-Message-Id response header.
        final messageId =
            response.headers.value('x-message-id') ?? 'unknown';
        PrimekitLogger.info(
          'Email sent via SendGrid. messageId=$messageId',
          tag: _tag,
        );
        return EmailResult.success(messageId: messageId);
      }

      final reason = _extractError(response.data) ??
          'Unexpected status code $statusCode';
      PrimekitLogger.warning(
        'SendGrid rejected email: $reason',
        tag: _tag,
      );
      return EmailResult.failure(reason: reason, statusCode: statusCode);
    } on DioException catch (e, stack) {
      PrimekitLogger.error(
        'SendGrid network error.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return EmailResult.failure(
        reason: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      PrimekitLogger.error(
        'Unexpected error sending via SendGrid.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return EmailResult.failure(reason: 'Unexpected error: $e');
    }
  }

  Map<String, dynamic> _buildPayload(EmailMessage message) {
    final from = <String, String>{'email': _fromEmail};
    if (_fromName != null) from['name'] = _fromName!;

    final to = <String, String>{'email': message.to};
    if (message.toName != null) to['name'] = message.toName!;

    final payload = <String, dynamic>{
      'personalizations': [
        {
          'to': [to],
        },
      ],
      'from': from,
      'subject': message.subject,
      'content': [
        if (message.textBody != null)
          {'type': 'text/plain', 'value': message.textBody},
        if (message.htmlBody != null)
          {'type': 'text/html', 'value': message.htmlBody},
      ],
    };

    if (message.replyTo != null) {
      payload['reply_to'] = {'email': message.replyTo};
    }

    if (message.attachments.isNotEmpty) {
      payload['attachments'] = message.attachments
          .map(
            (a) => {
              'filename': a.filename,
              'content': a.base64Content,
              'type': a.contentType,
            },
          )
          .toList();
    }

    if (message.headers.isNotEmpty) {
      payload['headers'] = message.headers;
    }

    return payload;
  }

  String? _extractError(dynamic data) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) return first['message']?.toString();
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Resend
// ---------------------------------------------------------------------------

/// Sends emails via the [Resend API](https://resend.com/docs/api-reference/emails/send-email).
///
/// **Required dependency:** `dio` (already in pubspec).
///
/// ```dart
/// EmailService.instance.configure(
///   provider: ResendProvider(
///     apiKey: Env.resendApiKey,
///     fromEmail: 'noreply@example.com',
///   ),
/// );
/// ```
class ResendProvider implements EmailProvider {
  /// Creates a Resend email provider.
  const ResendProvider({
    required String apiKey,
    required String fromEmail,
  })  : _apiKey = apiKey,
        _fromEmail = fromEmail;

  final String _apiKey;
  final String _fromEmail;

  static const String _endpoint = 'https://api.resend.com/emails';
  static const String _tag = 'ResendProvider';

  @override
  String get name => 'Resend';

  @override
  Future<EmailResult> send(EmailMessage message) async {
    final dio = Dio();

    try {
      final body = _buildPayload(message);

      final response = await dio.post<Map<String, dynamic>>(
        _endpoint,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      final responseData = response.data;

      if (statusCode == 200 || statusCode == 201) {
        final messageId =
            responseData?['id']?.toString() ?? 'unknown';
        PrimekitLogger.info(
          'Email sent via Resend. messageId=$messageId',
          tag: _tag,
        );
        return EmailResult.success(messageId: messageId);
      }

      final reason = responseData?['message']?.toString() ??
          responseData?['error']?.toString() ??
          'Unexpected status code $statusCode';
      PrimekitLogger.warning(
        'Resend rejected email: $reason',
        tag: _tag,
      );
      return EmailResult.failure(reason: reason, statusCode: statusCode);
    } on DioException catch (e, stack) {
      PrimekitLogger.error(
        'Resend network error.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return EmailResult.failure(
        reason: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      PrimekitLogger.error(
        'Unexpected error sending via Resend.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return EmailResult.failure(reason: 'Unexpected error: $e');
    }
  }

  Map<String, dynamic> _buildPayload(EmailMessage message) {
    final from = message.toName != null
        ? '${message.toName} <$_fromEmail>'
        : _fromEmail;

    final payload = <String, dynamic>{
      'from': from,
      'to': [message.to],
      'subject': message.subject,
    };

    if (message.textBody != null) payload['text'] = message.textBody;
    if (message.htmlBody != null) payload['html'] = message.htmlBody;
    if (message.replyTo != null) payload['reply_to'] = message.replyTo;

    if (message.headers.isNotEmpty) {
      payload['headers'] = message.headers;
    }

    if (message.attachments.isNotEmpty) {
      payload['attachments'] = message.attachments
          .map(
            (a) => {
              'filename': a.filename,
              'content': a.base64Content,
            },
          )
          .toList();
    }

    return payload;
  }
}

// ---------------------------------------------------------------------------
// SMTP (relay via backend)
// ---------------------------------------------------------------------------

/// Sends emails by posting to a backend relay endpoint that handles SMTP.
///
/// Direct SMTP connections from mobile apps are blocked by most carriers and
/// email providers. This provider sends your message payload to a backend
/// endpoint you control, which then relays it via SMTP.
///
/// **Backend contract:** POST to [relayUrl] with JSON body:
/// ```json
/// {
///   "to": "...",
///   "subject": "...",
///   "text": "...",
///   "html": "...",
///   "replyTo": "...",
///   "headers": {}
/// }
/// ```
/// The backend must return `{ "messageId": "..." }` on success.
///
/// For a simple backend relay using Node.js + Nodemailer, see the Primekit
/// documentation.
class SmtpProvider implements EmailProvider {
  /// Creates an SMTP relay provider.
  ///
  /// [relayUrl] is the URL of your backend relay endpoint.
  /// [authToken] is an optional bearer token to authenticate with your relay.
  const SmtpProvider({
    required String host,
    required int port,
    String? username,
    String? password,
    bool ssl = true,
    required String relayUrl,
    String? authToken,
  })  : _host = host,
        _port = port,
        _username = username,
        _password = password,
        _ssl = ssl,
        _relayUrl = relayUrl,
        _authToken = authToken;

  final String _host;
  final int _port;
  final String? _username;
  final String? _password;
  final bool _ssl;
  final String _relayUrl;
  final String? _authToken;

  static const String _tag = 'SmtpProvider';

  @override
  String get name => 'SMTP';

  /// SMTP host (e.g. `'smtp.gmail.com'`).
  String get host => _host;

  /// SMTP port (e.g. `587` for TLS, `465` for SSL).
  int get port => _port;

  /// Whether to use SSL.
  bool get ssl => _ssl;

  @override
  Future<EmailResult> send(EmailMessage message) async {
    // Direct SMTP from Dart mobile is not viable (carrier blocks, no socket
    // access in some environments). This implementation posts to a relay.
    final dio = Dio();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      final body = <String, dynamic>{
        'smtp': {
          'host': _host,
          'port': _port,
          'ssl': _ssl,
          if (_username != null) 'username': _username,
          if (_password != null) 'password': _password,
        },
        'to': message.to,
        'subject': message.subject,
        if (message.toName != null) 'toName': message.toName,
        if (message.textBody != null) 'text': message.textBody,
        if (message.htmlBody != null) 'html': message.htmlBody,
        if (message.replyTo != null) 'replyTo': message.replyTo,
        if (message.headers.isNotEmpty) 'headers': message.headers,
        if (message.attachments.isNotEmpty)
          'attachments': message.attachments
              .map(
                (a) => {
                  'filename': a.filename,
                  'content': a.base64Content,
                  'contentType': a.contentType,
                },
              )
              .toList(),
      };

      final response = await dio.post<Map<String, dynamic>>(
        _relayUrl,
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      final responseData = response.data;

      if (statusCode >= 200 && statusCode < 300) {
        final messageId =
            responseData?['messageId']?.toString() ?? 'smtp-relay';
        PrimekitLogger.info(
          'Email sent via SMTP relay. messageId=$messageId',
          tag: _tag,
        );
        return EmailResult.success(messageId: messageId);
      }

      final reason = responseData?['error']?.toString() ??
          responseData?['message']?.toString() ??
          'Relay returned status $statusCode';
      PrimekitLogger.warning(
        'SMTP relay rejected email: $reason',
        tag: _tag,
      );
      return EmailResult.failure(reason: reason, statusCode: statusCode);
    } on DioException catch (e, stack) {
      PrimekitLogger.error(
        'SMTP relay network error.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return EmailResult.failure(
        reason: e.message ?? 'Network error reaching relay',
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      PrimekitLogger.error(
        'Unexpected error sending via SMTP relay.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return EmailResult.failure(reason: 'Unexpected error: $e');
    }
  }
}
