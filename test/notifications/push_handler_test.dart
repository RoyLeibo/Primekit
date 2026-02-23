import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/notifications/push_handler.dart';

void main() {
  setUp(() => PushHandler.instance.resetForTesting());

  group('PushHandler', () {
    test('instance is singleton', () {
      expect(identical(PushHandler.instance, PushHandler.instance), isTrue);
    });

    test('getToken returns null before initialize', () async {
      final token = await PushHandler.instance.getToken();
      expect(token, isNull);
    });

    test('requestPermission returns false before initialize', () async {
      final granted = await PushHandler.instance.requestPermission();
      expect(granted, isFalse);
    });

    group('initialize()', () {
      test('initializes without error', () async {
        await PushHandler.instance.initialize(
          onMessage: (_) {},
          onMessageOpenedApp: (_) {},
        );
        // No exception thrown means success.
      });

      test('calling initialize twice does not throw', () async {
        await PushHandler.instance.initialize(
          onMessage: (_) {},
          onMessageOpenedApp: (_) {},
        );
        await PushHandler.instance.initialize(
          onMessage: (_) {},
          onMessageOpenedApp: (_) {},
        );
        // Should log a warning and return — no exception.
      });
    });

    group('simulateMessage()', () {
      test('fires onMessage callback', () async {
        PushMessage? received;
        await PushHandler.instance.initialize(
          onMessage: (msg) => received = msg,
          onMessageOpenedApp: (_) {},
        );

        PushHandler.instance.simulateMessage(
          const PushMessage(title: 'Test', body: 'Hello!', messageId: 'sim-1'),
        );

        expect(received, isNotNull);
        expect(received!.title, equals('Test'));
        expect(received!.body, equals('Hello!'));
        expect(received!.messageId, equals('sim-1'));
      });
    });

    group('simulateOpenedApp()', () {
      test('fires onMessageOpenedApp callback', () async {
        PushMessage? opened;
        await PushHandler.instance.initialize(
          onMessage: (_) {},
          onMessageOpenedApp: (msg) => opened = msg,
        );

        PushHandler.instance.simulateOpenedApp(
          const PushMessage(title: 'Tapped', data: {'route': '/home'}),
        );

        expect(opened, isNotNull);
        expect(opened!.data['route'], equals('/home'));
      });
    });

    group('PushMessage', () {
      test('all fields accessible', () {
        const msg = PushMessage(
          title: 'Title',
          body: 'Body',
          data: {'key': 'value'},
          collapseKey: 'ck-1',
          messageId: 'msg-1',
        );
        expect(msg.title, equals('Title'));
        expect(msg.body, equals('Body'));
        expect(msg.data['key'], equals('value'));
        expect(msg.collapseKey, equals('ck-1'));
        expect(msg.messageId, equals('msg-1'));
      });

      test('data defaults to empty map', () {
        const msg = PushMessage();
        expect(msg.data, isEmpty);
      });

      test('toString includes title and body', () {
        const msg = PushMessage(title: 'Hi', body: 'There');
        expect(msg.toString(), contains('Hi'));
        expect(msg.toString(), contains('There'));
      });
    });
  });
}
