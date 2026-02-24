// Tests for the LocalNotifier stub (which runs on the test VM, not a browser).
// These tests verify the public API surface and default return values.

import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/notifications/local_notifier_stub.dart';

void main() {
  group('LocalNotifier stub (web/unsupported platforms)', () {
    late LocalNotifier notifier;

    setUp(() {
      notifier = LocalNotifier.instance;
      notifier.resetForTesting();
    });

    test('initialize() completes without error', () async {
      await expectLater(
        notifier.initialize(),
        completes,
      );
    });

    test('show() completes without error', () async {
      await expectLater(
        notifier.show(id: 1, title: 'Test', body: 'Body'),
        completes,
      );
    });

    test('schedule() completes without error', () async {
      await expectLater(
        notifier.schedule(
          id: 2,
          title: 'Scheduled',
          body: 'Body',
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        completes,
      );
    });

    test('cancel() completes without error', () async {
      await expectLater(notifier.cancel(1), completes);
    });

    test('cancelAll() completes without error', () async {
      await expectLater(notifier.cancelAll(), completes);
    });

    test('getPending() returns empty list', () async {
      final pending = await notifier.getPending();
      expect(pending, isEmpty);
    });

    test('onTap stream does not emit immediately', () async {
      final events = <Object>[];
      final sub = notifier.onTap.listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events, isEmpty);
      await sub.cancel();
    });
  });
}
