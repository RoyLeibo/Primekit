import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/email/email_message.dart';

void main() {
  group('EmailAttachment', () {
    final attachment = EmailAttachment(
      filename: 'report.pdf',
      content: utf8.encode('fake pdf content'),
      contentType: 'application/pdf',
    );

    test('base64Content returns valid base64 string', () {
      final decoded = base64Decode(attachment.base64Content);
      expect(decoded, equals(attachment.content));
    });

    test('copyWith preserves unchanged fields', () {
      final copy = attachment.copyWith(filename: 'new.pdf');
      expect(copy.filename, equals('new.pdf'));
      expect(copy.contentType, equals('application/pdf'));
      expect(copy.content, equals(attachment.content));
    });

    test('toString includes filename and contentType', () {
      expect(attachment.toString(), contains('report.pdf'));
      expect(attachment.toString(), contains('application/pdf'));
    });
  });

  group('EmailMessage', () {
    const minimal = EmailMessage(
      to: 'alice@example.com',
      subject: 'Hello',
    );

    test('required fields are set correctly', () {
      expect(minimal.to, equals('alice@example.com'));
      expect(minimal.subject, equals('Hello'));
      expect(minimal.attachments, isEmpty);
      expect(minimal.headers, isEmpty);
    });

    test('optional fields default to null', () {
      expect(minimal.toName, isNull);
      expect(minimal.textBody, isNull);
      expect(minimal.htmlBody, isNull);
      expect(minimal.replyTo, isNull);
    });

    test('copyWith replaces only specified fields', () {
      final copy = minimal.copyWith(
        to: 'bob@example.com',
        htmlBody: '<p>Hi</p>',
      );
      expect(copy.to, equals('bob@example.com'));
      expect(copy.subject, equals('Hello')); // unchanged
      expect(copy.htmlBody, equals('<p>Hi</p>'));
      expect(copy.textBody, isNull); // unchanged
    });

    test('copyWith preserves attachments', () {
      final attachment = EmailAttachment(
        filename: 'a.txt',
        content: [1, 2, 3],
        contentType: 'text/plain',
      );
      final withAttachment = minimal.copyWith(attachments: [attachment]);
      final copy = withAttachment.copyWith(subject: 'Updated');
      expect(copy.attachments, equals(withAttachment.attachments));
    });

    test('toString includes to and subject', () {
      expect(minimal.toString(), contains('alice@example.com'));
      expect(minimal.toString(), contains('Hello'));
    });

    test('full construction with all fields', () {
      final message = EmailMessage(
        to: 'bob@example.com',
        toName: 'Bob',
        subject: 'Full',
        textBody: 'Text',
        htmlBody: '<p>HTML</p>',
        replyTo: 'noreply@example.com',
        attachments: [
          EmailAttachment(
            filename: 'a.txt',
            content: [65],
            contentType: 'text/plain',
          ),
        ],
        headers: {'X-Custom': 'value'},
      );

      expect(message.toName, equals('Bob'));
      expect(message.textBody, equals('Text'));
      expect(message.htmlBody, equals('<p>HTML</p>'));
      expect(message.replyTo, equals('noreply@example.com'));
      expect(message.attachments, hasLength(1));
      expect(message.headers['X-Custom'], equals('value'));
    });
  });

  group('EmailResult', () {
    test('EmailSuccess isSuccess is true and isFailure is false', () {
      const result = EmailSuccess(messageId: 'msg-123');
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('EmailFailure isFailure is true and isSuccess is false', () {
      const result = EmailFailure(reason: 'bad request', statusCode: 400);
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('factory constructors build correct types', () {
      final success = EmailResult.success(messageId: 'abc');
      final failure = EmailResult.failure(reason: 'err', statusCode: 500);
      expect(success, isA<EmailSuccess>());
      expect(failure, isA<EmailFailure>());
    });

    test('when() calls success branch', () {
      final result = EmailResult.success(messageId: 'x');
      final output = result.when(
        success: (r) => r.messageId,
        failure: (_) => 'fail',
      );
      expect(output, equals('x'));
    });

    test('when() calls failure branch', () {
      final result = EmailResult.failure(reason: 'oops');
      final output = result.when(
        success: (_) => 'ok',
        failure: (r) => r.reason,
      );
      expect(output, equals('oops'));
    });

    test('EmailSuccess equality based on messageId', () {
      const a = EmailSuccess(messageId: 'abc');
      const b = EmailSuccess(messageId: 'abc');
      const c = EmailSuccess(messageId: 'xyz');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('EmailFailure equality based on reason and statusCode', () {
      const a = EmailFailure(reason: 'err', statusCode: 400);
      const b = EmailFailure(reason: 'err', statusCode: 400);
      const c = EmailFailure(reason: 'err', statusCode: 500);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('EmailFailure statusCode can be null', () {
      const result = EmailFailure(reason: 'timeout');
      expect(result.statusCode, isNull);
    });

    test('toString includes relevant fields', () {
      const success = EmailSuccess(messageId: 'msg-1');
      const failure = EmailFailure(reason: 'bad', statusCode: 422);
      expect(success.toString(), contains('msg-1'));
      expect(failure.toString(), contains('bad'));
      expect(failure.toString(), contains('422'));
    });
  });
}
