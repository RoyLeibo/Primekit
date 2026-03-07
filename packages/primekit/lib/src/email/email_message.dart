import 'dart:convert';

/// A single file attachment to include with an [EmailMessage].
final class EmailAttachment {
  /// Creates an email attachment.
  const EmailAttachment({
    required this.filename,
    required this.content,
    required this.contentType,
  });

  /// The filename shown to the recipient (e.g. `'report.pdf'`).
  final String filename;

  /// Raw byte content of the attachment.
  final List<int> content;

  /// MIME content type (e.g. `'application/pdf'`, `'image/png'`).
  final String contentType;

  /// Returns the content as a Base64-encoded string (required by most APIs).
  String get base64Content => base64Encode(content);

  /// Returns a copy with the given fields replaced.
  EmailAttachment copyWith({
    String? filename,
    List<int>? content,
    String? contentType,
  }) => EmailAttachment(
    filename: filename ?? this.filename,
    content: content ?? List.unmodifiable(this.content),
    contentType: contentType ?? this.contentType,
  );

  @override
  String toString() =>
      'EmailAttachment(filename: $filename, contentType: $contentType, '
      'bytes: ${content.length})';
}

/// An immutable email message ready for delivery by an [EmailProvider].
///
/// At least one of [textBody] or [htmlBody] must be provided.
///
/// ```dart
/// final message = EmailMessage(
///   to: 'alice@example.com',
///   subject: 'Welcome!',
///   htmlBody: '<h1>Hi Alice</h1>',
/// );
/// ```
final class EmailMessage {
  /// Creates an email message.
  ///
  /// [to] and [subject] are required. At least one of [textBody] or [htmlBody]
  /// should be set; providers will reject messages with neither.
  const EmailMessage({
    required this.to,
    required this.subject,
    this.toName,
    this.textBody,
    this.htmlBody,
    this.replyTo,
    this.attachments = const [],
    this.headers = const {},
  });

  /// Recipient email address.
  final String to;

  /// Optional display name for the recipient.
  final String? toName;

  /// Email subject line.
  final String subject;

  /// Plain-text body. Shown when the client cannot render HTML.
  final String? textBody;

  /// HTML body. Takes priority over [textBody] in capable clients.
  final String? htmlBody;

  /// Optional reply-to address.
  final String? replyTo;

  /// File attachments. Defaults to an empty list.
  final List<EmailAttachment> attachments;

  /// Additional email headers (e.g. `{'X-Campaign-Id': '42'}`).
  final Map<String, String> headers;

  /// Returns a copy with the given fields replaced.
  EmailMessage copyWith({
    String? to,
    String? toName,
    String? subject,
    String? textBody,
    String? htmlBody,
    String? replyTo,
    List<EmailAttachment>? attachments,
    Map<String, String>? headers,
  }) => EmailMessage(
    to: to ?? this.to,
    toName: toName ?? this.toName,
    subject: subject ?? this.subject,
    textBody: textBody ?? this.textBody,
    htmlBody: htmlBody ?? this.htmlBody,
    replyTo: replyTo ?? this.replyTo,
    attachments: attachments ?? List.unmodifiable(this.attachments),
    headers: headers ?? Map.unmodifiable(this.headers),
  );

  @override
  String toString() =>
      'EmailMessage(to: $to, subject: $subject, '
      'attachments: ${attachments.length})';
}

// ---------------------------------------------------------------------------
// EmailResult
// ---------------------------------------------------------------------------

/// The result of an email send attempt.
sealed class EmailResult {
  const EmailResult();

  /// Creates a successful send result with the provider's [messageId].
  const factory EmailResult.success({required String messageId}) = EmailSuccess;

  /// Creates a failure result with a human-readable [reason] and optional
  /// HTTP [statusCode].
  const factory EmailResult.failure({required String reason, int? statusCode}) =
      EmailFailure;

  /// Returns `true` if the email was sent successfully.
  bool get isSuccess => this is EmailSuccess;

  /// Returns `true` if the send attempt failed.
  bool get isFailure => this is EmailFailure;

  /// Exhaustively maps this result to a value of type [T].
  T when<T>({
    required T Function(EmailSuccess result) success,
    required T Function(EmailFailure result) failure,
  }) => switch (this) {
    EmailSuccess() => success(this as EmailSuccess),
    EmailFailure() => failure(this as EmailFailure),
  };
}

/// The success variant of [EmailResult].
final class EmailSuccess extends EmailResult {
  /// Creates a successful email result.
  const EmailSuccess({required this.messageId});

  /// The message ID returned by the email provider.
  final String messageId;

  @override
  String toString() => 'EmailResult.success(messageId: $messageId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSuccess && messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;
}

/// The failure variant of [EmailResult].
final class EmailFailure extends EmailResult {
  /// Creates a failed email result.
  const EmailFailure({required this.reason, this.statusCode});

  /// Human-readable reason for the failure.
  final String reason;

  /// HTTP status code returned by the provider, if applicable.
  final int? statusCode;

  @override
  String toString() =>
      'EmailResult.failure(reason: $reason, statusCode: $statusCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailFailure &&
          reason == other.reason &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(reason, statusCode);
}
