import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/core/exceptions.dart';
import 'package:primekit/src/email/email_message.dart';
import 'package:primekit/src/email/email_provider.dart';
import 'package:primekit/src/email/email_service.dart';

// ---------------------------------------------------------------------------
// Fake provider for testing
// ---------------------------------------------------------------------------

class _FakeProvider implements EmailProvider {
  _FakeProvider({
    required String name,
    required EmailResult Function(EmailMessage) handler,
  }) : _name = name,
       _handler = handler;

  final String _name;
  final EmailResult Function(EmailMessage) _handler;

  final List<EmailMessage> sentMessages = [];

  @override
  String get name => _name;

  @override
  Future<EmailResult> send(EmailMessage message) async {
    sentMessages.add(message);
    return _handler(message);
  }
}

void main() {
  setUp(() {
    EmailService.instance.resetForTesting();
  });

  group('EmailService', () {
    const message = EmailMessage(
      to: 'test@example.com',
      subject: 'Test',
      textBody: 'Hello',
    );

    test('throws ConfigurationException when not configured', () {
      expect(
        () => EmailService.instance.send(message),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('isConfigured returns false before configure()', () {
      expect(EmailService.instance.isConfigured, isFalse);
    });

    test('isConfigured returns true after configure()', () {
      final provider = _FakeProvider(
        name: 'Test',
        handler: (_) => const EmailSuccess(messageId: 'id'),
      );
      EmailService.instance.configure(provider: provider);
      expect(EmailService.instance.isConfigured, isTrue);
    });

    test('providerName returns null before configure()', () {
      expect(EmailService.instance.providerName, isNull);
    });

    test('providerName returns provider name after configure()', () {
      EmailService.instance.configure(
        provider: _FakeProvider(
          name: 'MyProvider',
          handler: (_) => const EmailSuccess(messageId: 'x'),
        ),
      );
      expect(EmailService.instance.providerName, equals('MyProvider'));
    });

    test('send delegates to configured provider', () async {
      final provider = _FakeProvider(
        name: 'TestProvider',
        handler: (_) => const EmailSuccess(messageId: 'msg-42'),
      );
      EmailService.instance.configure(provider: provider);

      final result = await EmailService.instance.send(message);

      expect(result.isSuccess, isTrue);
      expect((result as EmailSuccess).messageId, equals('msg-42'));
      expect(provider.sentMessages, hasLength(1));
      expect(provider.sentMessages.first.to, equals('test@example.com'));
    });

    test('send passes failure result through without throwing', () async {
      final provider = _FakeProvider(
        name: 'FailProvider',
        handler: (_) =>
            const EmailFailure(reason: 'quota exceeded', statusCode: 429),
      );
      EmailService.instance.configure(provider: provider);

      final result = await EmailService.instance.send(message);

      expect(result.isFailure, isTrue);
      expect((result as EmailFailure).statusCode, equals(429));
    });

    test('configure can be called again to swap providers', () async {
      final providerA = _FakeProvider(
        name: 'A',
        handler: (_) => const EmailSuccess(messageId: 'from-a'),
      );
      final providerB = _FakeProvider(
        name: 'B',
        handler: (_) => const EmailSuccess(messageId: 'from-b'),
      );

      EmailService.instance.configure(provider: providerA);
      EmailService.instance.configure(provider: providerB);

      final result = await EmailService.instance.send(message);
      expect((result as EmailSuccess).messageId, equals('from-b'));
      expect(providerA.sentMessages, isEmpty);
      expect(providerB.sentMessages, hasLength(1));
    });

    test('instance is a singleton', () {
      expect(identical(EmailService.instance, EmailService.instance), isTrue);
    });

    test('resetForTesting clears provider', () {
      EmailService.instance.configure(
        provider: _FakeProvider(
          name: 'X',
          handler: (_) => const EmailSuccess(messageId: 'x'),
        ),
      );
      EmailService.instance.resetForTesting();
      expect(EmailService.instance.isConfigured, isFalse);
    });
  });
}
