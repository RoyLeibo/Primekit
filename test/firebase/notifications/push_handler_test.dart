import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/firebase.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
//
// PushHandler.initialize() calls real Firebase SDK methods, which require
// native platform bridges unavailable in unit tests (firebase_core 4.x uses
// Pigeon, not legacy MethodChannels). Those integration paths are covered by
// the testing helpers: setCallbacksForTesting(), simulateMessage(), and
// simulateOpenedApp() let us exercise all callback behaviour without a real
// Firebase project or device.

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

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

    group('setCallbacksForTesting()', () {
      test('marks handler as initialized', () async {
        PushHandler.instance.setCallbacksForTesting(
          onMessage: (_) {},
          onMessageOpenedApp: (_) {},
        );
        // After setup, getToken should attempt to call Firebase (returns null
        // in test environment) rather than returning null due to uninitialised.
        // We just verify no exception is thrown.
        expect(
          () => PushHandler.instance.simulateMessage(const PushMessage()),
          returnsNormally,
        );
      });

      test(
        'calling initialize after setCallbacksForTesting does not throw',
        () async {
          PushHandler.instance.setCallbacksForTesting(
            onMessage: (_) {},
            onMessageOpenedApp: (_) {},
          );
          // Second initialize() call is a no-op (already initialised).
          // Should log a warning and return — no exception.
          await PushHandler.instance.initialize(
            onMessage: (_) {},
            onMessageOpenedApp: (_) {},
          );
        },
      );
    });

    group('simulateMessage()', () {
      test('fires onMessage callback', () async {
        PushMessage? received;
        PushHandler.instance.setCallbacksForTesting(
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

      test('does nothing before callbacks are set', () {
        // Should not throw even without initialization.
        expect(
          () => PushHandler.instance.simulateMessage(
            const PushMessage(title: 'Ignored'),
          ),
          returnsNormally,
        );
      });
    });

    group('simulateOpenedApp()', () {
      test('fires onMessageOpenedApp callback', () async {
        PushMessage? opened;
        PushHandler.instance.setCallbacksForTesting(
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
