import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/email/email_message.dart';
import 'package:primekit/src/email/email_provider.dart';
import 'package:primekit/src/email/email_service.dart';
import 'package:primekit/src/email/verification_mailer.dart';

class _CaptureProvider implements EmailProvider {
  final List<EmailMessage> captured = [];
  final EmailResult result;

  _CaptureProvider({this.result = const EmailSuccess(messageId: 'test-id')});

  @override
  String get name => 'Capture';

  @override
  Future<EmailResult> send(EmailMessage message) async {
    captured.add(message);
    return result;
  }
}

void main() {
  setUp(() => EmailService.instance.resetForTesting());

  group('VerificationMailer', () {
    late _CaptureProvider provider;
    late VerificationMailer mailer;

    setUp(() {
      provider = _CaptureProvider();
      EmailService.instance.configure(provider: provider);
      mailer = const VerificationMailer(
        fromEmail: 'noreply@myapp.com',
        appName: 'MyApp',
        otpTtl: Duration(minutes: 10),
      );
    });

    // -------------------------------------------------------------------------
    // sendOtp
    // -------------------------------------------------------------------------

    group('sendOtp', () {
      test('sends to correct address', () async {
        await mailer.sendOtp(toEmail: 'user@example.com', otp: '123456');
        expect(provider.captured.first.to, equals('user@example.com'));
      });

      test('subject contains app name', () async {
        await mailer.sendOtp(toEmail: 'user@example.com', otp: '654321');
        expect(
          provider.captured.first.subject.toLowerCase(),
          contains('myapp'),
        );
      });

      test('text body contains otp code', () async {
        await mailer.sendOtp(toEmail: 'user@example.com', otp: '847261');
        expect(provider.captured.first.textBody, contains('847261'));
      });

      test('html body contains otp code', () async {
        await mailer.sendOtp(toEmail: 'user@example.com', otp: '111222');
        expect(provider.captured.first.htmlBody, contains('111222'));
      });

      test('html body shows ttl in minutes', () async {
        await mailer.sendOtp(toEmail: 'user@example.com', otp: '000000');
        expect(provider.captured.first.htmlBody, contains('10'));
        expect(provider.captured.first.htmlBody, contains('minute'));
      });

      test('html body shows ttl in hours for 2h duration', () async {
        const longMailer = VerificationMailer(
          fromEmail: 'noreply@app.com',
          appName: 'App',
          otpTtl: Duration(hours: 2),
        );
        await longMailer.sendOtp(toEmail: 'u@u.com', otp: '123');
        expect(provider.captured.first.htmlBody, contains('2'));
        expect(provider.captured.first.htmlBody, contains('hour'));
      });

      test('both text and html bodies are set', () async {
        await mailer.sendOtp(toEmail: 'u@u.com', otp: '999');
        expect(provider.captured.first.textBody, isNotNull);
        expect(provider.captured.first.htmlBody, isNotNull);
      });

      test('html is valid html document', () async {
        await mailer.sendOtp(toEmail: 'u@u.com', otp: '555');
        final html = provider.captured.first.htmlBody!;
        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('</html>'));
      });

      test('returns provider result', () async {
        final result = await mailer.sendOtp(toEmail: 'u@u.com', otp: '111');
        expect(result.isSuccess, isTrue);
        expect((result as EmailSuccess).messageId, equals('test-id'));
      });
    });

    // -------------------------------------------------------------------------
    // sendVerificationLink
    // -------------------------------------------------------------------------

    group('sendVerificationLink', () {
      const verificationUrl = 'https://myapp.com/verify?token=abc123secret';

      test('sends to correct address', () async {
        await mailer.sendVerificationLink(
          toEmail: 'user@example.com',
          verificationUrl: verificationUrl,
        );
        expect(provider.captured.first.to, equals('user@example.com'));
      });

      test('subject contains verify keyword', () async {
        await mailer.sendVerificationLink(
          toEmail: 'u@u.com',
          verificationUrl: verificationUrl,
        );
        expect(
          provider.captured.first.subject.toLowerCase(),
          contains('verif'),
        );
      });

      test('text body contains verification url', () async {
        await mailer.sendVerificationLink(
          toEmail: 'u@u.com',
          verificationUrl: verificationUrl,
        );
        expect(provider.captured.first.textBody, contains(verificationUrl));
      });

      test('html body contains verification url', () async {
        await mailer.sendVerificationLink(
          toEmail: 'u@u.com',
          verificationUrl: verificationUrl,
        );
        expect(provider.captured.first.htmlBody, contains(verificationUrl));
      });

      test('html body contains a clickable button', () async {
        await mailer.sendVerificationLink(
          toEmail: 'u@u.com',
          verificationUrl: verificationUrl,
        );
        final html = provider.captured.first.htmlBody!;
        expect(html, contains('<a href="'));
      });
    });

    // -------------------------------------------------------------------------
    // sendWelcome
    // -------------------------------------------------------------------------

    group('sendWelcome', () {
      test('sends to correct address', () async {
        await mailer.sendWelcome(
          toEmail: 'newuser@example.com',
          userName: 'Alice',
        );
        expect(provider.captured.first.to, equals('newuser@example.com'));
      });

      test('toName is set on the message', () async {
        await mailer.sendWelcome(
          toEmail: 'newuser@example.com',
          userName: 'Alice',
        );
        expect(provider.captured.first.toName, equals('Alice'));
      });

      test('subject contains user name', () async {
        await mailer.sendWelcome(toEmail: 'u@u.com', userName: 'Bob');
        expect(provider.captured.first.subject, contains('Bob'));
      });

      test('html body contains user name', () async {
        await mailer.sendWelcome(toEmail: 'u@u.com', userName: 'Charlie');
        expect(provider.captured.first.htmlBody, contains('Charlie'));
      });

      test('html body contains app name', () async {
        await mailer.sendWelcome(toEmail: 'u@u.com', userName: 'Dave');
        expect(provider.captured.first.htmlBody, contains('MyApp'));
      });

      test('html escapes user name with special characters', () async {
        await mailer.sendWelcome(toEmail: 'u@u.com', userName: '<b>XSS</b>');
        final html = provider.captured.first.htmlBody!;
        expect(html, isNot(contains('<b>XSS</b>')));
        expect(html, contains('&lt;b&gt;'));
      });
    });
  });
}
