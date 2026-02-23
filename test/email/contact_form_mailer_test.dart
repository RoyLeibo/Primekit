import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/email/contact_form_mailer.dart';
import 'package:primekit/src/email/email_message.dart';
import 'package:primekit/src/email/email_provider.dart';
import 'package:primekit/src/email/email_service.dart';

class _CaptureProvider implements EmailProvider {
  _CaptureProvider({required this.result});

  final EmailResult result;
  final List<EmailMessage> captured = [];

  @override
  String get name => 'Capture';

  @override
  Future<EmailResult> send(EmailMessage message) async {
    captured.add(message);
    return result;
  }
}

class _FailThenSucceedProvider implements EmailProvider {
  _FailThenSucceedProvider({required int failCount})
    : _failsRemaining = failCount;

  int _failsRemaining;
  int callCount = 0;

  @override
  String get name => 'FailThenSucceed';

  @override
  Future<EmailResult> send(EmailMessage message) async {
    callCount++;
    if (_failsRemaining > 0) {
      _failsRemaining--;
      return const EmailFailure(reason: 'transient error', statusCode: 503);
    }
    return const EmailSuccess(messageId: 'retry-success');
  }
}

void main() {
  setUp(() => EmailService.instance.resetForTesting());

  group('ContactFormMailer', () {
    test('sends email to configured toEmail', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
      await mailer.send(
        senderName: 'Alice',
        senderEmail: 'alice@example.com',
        message: 'Hello!',
      );

      expect(provider.captured, hasLength(1));
      expect(provider.captured.first.to, equals('support@myapp.com'));
    });

    test('email subject matches configured subject', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(
        toEmail: 'support@myapp.com',
        subject: 'Custom Subject',
      );
      await mailer.send(
        senderName: 'Bob',
        senderEmail: 'bob@example.com',
        message: 'Hi',
      );

      expect(provider.captured.first.subject, equals('Custom Subject'));
    });

    test('email body contains sender name and email', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
      await mailer.send(
        senderName: 'Charlie',
        senderEmail: 'charlie@example.com',
        message: 'A question',
      );

      final sent = provider.captured.first;
      expect(sent.textBody, contains('Charlie'));
      expect(sent.textBody, contains('charlie@example.com'));
      expect(sent.htmlBody, contains('Charlie'));
    });

    test('email body contains message text', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      const messageText = 'I need help with my account';
      final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
      await mailer.send(
        senderName: 'Dave',
        senderEmail: 'dave@example.com',
        message: messageText,
      );

      expect(provider.captured.first.textBody, contains(messageText));
    });

    test('additional fields appear in both text and HTML bodies', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
      await mailer.send(
        senderName: 'Eve',
        senderEmail: 'eve@example.com',
        message: 'Help!',
        additionalFields: {'Phone': '+1-555-0100', 'Company': 'ACME'},
      );

      final sent = provider.captured.first;
      expect(sent.textBody, contains('Phone'));
      expect(sent.textBody, contains('+1-555-0100'));
      expect(sent.htmlBody, contains('ACME'));
    });

    test('returns success result on first try', () async {
      EmailService.instance.configure(
        provider: _CaptureProvider(
          result: const EmailSuccess(messageId: 'fast'),
        ),
      );

      final mailer = ContactFormMailer(toEmail: 'a@b.com');
      final result = await mailer.send(
        senderName: 'X',
        senderEmail: 'x@x.com',
        message: 'hi',
      );

      expect(result.isSuccess, isTrue);
      expect((result as EmailSuccess).messageId, equals('fast'));
    });

    test('retries on transient failure and succeeds', () async {
      final provider = _FailThenSucceedProvider(failCount: 1);
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'a@b.com', maxRetries: 3);
      final result = await mailer.send(
        senderName: 'X',
        senderEmail: 'x@x.com',
        message: 'test',
      );

      expect(result.isSuccess, isTrue);
      expect(provider.callCount, equals(2)); // 1 fail + 1 success
    });

    test('stops retrying on 4xx client error', () async {
      var calls = 0;
      final provider = _CaptureProvider(
        result: const EmailFailure(reason: 'invalid', statusCode: 400),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'a@b.com', maxRetries: 3);
      final result = await mailer.send(
        senderName: 'X',
        senderEmail: 'x@x.com',
        message: 'test',
      );

      expect(result.isFailure, isTrue);
      // Should not retry on 400
      expect(provider.captured, hasLength(1));
    });

    test('returns failure after all retries exhausted', () async {
      final provider = _FailThenSucceedProvider(failCount: 99);
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'a@b.com', maxRetries: 3);
      final result = await mailer.send(
        senderName: 'X',
        senderEmail: 'x@x.com',
        message: 'test',
      );

      expect(result.isFailure, isTrue);
      expect(provider.callCount, equals(3));
    });

    test('HTML body is valid HTML with required structure', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
      await mailer.send(
        senderName: 'Frank',
        senderEmail: 'frank@example.com',
        message: 'Question here',
      );

      final html = provider.captured.first.htmlBody!;
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<html'));
      expect(html, contains('</html>'));
      expect(html, contains('Frank'));
    });

    test('HTML escapes special characters in sender name', () async {
      final provider = _CaptureProvider(
        result: const EmailSuccess(messageId: 'ok'),
      );
      EmailService.instance.configure(provider: provider);

      final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
      await mailer.send(
        senderName: '<script>alert(1)</script>',
        senderEmail: 'x@x.com',
        message: 'xss test',
      );

      final html = provider.captured.first.htmlBody!;
      expect(html, isNot(contains('<script>')));
      expect(html, contains('&lt;script&gt;'));
    });
  });
}
