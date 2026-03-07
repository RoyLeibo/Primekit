import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:primekit/src/network/offline_queue.dart';
import 'package:primekit/src/network/connectivity_monitor.dart';
import 'package:primekit_core/primekit_core.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QueuedRequest _makeRequest({
  String id = 'req-1',
  String method = 'POST',
  String url = 'https://api.example.com/events',
  int maxRetries = 3,
  int retryCount = 0,
  Object? body,
}) => QueuedRequest(
  id: id,
  method: method,
  url: url,
  enqueuedAt: DateTime.utc(2026, 1, 1),
  body: body,
  maxRetries: maxRetries,
  retryCount: retryCount,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Start offline so enqueue does not auto-flush during tests.
    ConnectivityMonitor.instance.injectStatusForTesting(false);
  });

  tearDown(() async {
    await OfflineQueue.instance.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // QueuedRequest
  // ---------------------------------------------------------------------------

  group('QueuedRequest', () {
    test('toJson / fromJson round-trip', () {
      final req = _makeRequest(body: {'key': 'value'});
      final json = req.toJson();
      final restored = QueuedRequest.fromJson(json.cast<String, Object?>());

      expect(restored.id, req.id);
      expect(restored.method, req.method);
      expect(restored.url, req.url);
      expect(restored.maxRetries, req.maxRetries);
      expect(restored.retryCount, req.retryCount);
      expect(restored.enqueuedAt, req.enqueuedAt);
    });

    test('withIncrementedRetry increases retryCount by 1', () {
      final req = _makeRequest(retryCount: 2);
      final incremented = req.withIncrementedRetry();
      expect(incremented.retryCount, 3);
    });

    test('withIncrementedRetry preserves other fields', () {
      final req = _makeRequest(id: 'abc', method: 'DELETE', maxRetries: 5);
      final incremented = req.withIncrementedRetry();
      expect(incremented.id, 'abc');
      expect(incremented.method, 'DELETE');
      expect(incremented.maxRetries, 5);
    });

    test('fromJson uses defaults for missing fields', () {
      final req = QueuedRequest.fromJson({
        'id': 'x',
        'url': 'https://example.com',
        'enqueuedAt': DateTime.utc(2026).toIso8601String(),
      });
      expect(req.method, 'GET');
      expect(req.maxRetries, 3);
      expect(req.retryCount, 0);
      expect(req.headers, isEmpty);
    });

    test('toString contains id method and url', () {
      final req = _makeRequest();
      final s = req.toString();
      expect(s, contains('req-1'));
      expect(s, contains('POST'));
      expect(s, contains('https://api.example.com/events'));
    });
  });

  // ---------------------------------------------------------------------------
  // OfflineQueueEvent sealed types
  // ---------------------------------------------------------------------------

  group('OfflineQueueEvent types', () {
    test('RequestEnqueuedEvent holds request', () {
      final req = _makeRequest();
      final event = RequestEnqueuedEvent(req);
      expect(event.request, same(req));
    });

    test('RequestFlushedEvent holds request', () {
      final req = _makeRequest();
      final event = RequestFlushedEvent(req);
      expect(event.request, same(req));
    });

    test('RequestDroppedEvent holds request and error', () {
      final req = _makeRequest();
      const err = NoConnectivityException();
      final event = RequestDroppedEvent(req, err);
      expect(event.request, same(req));
      expect(event.error, same(err));
    });

    test('FlushStartedEvent holds pending count', () {
      const event = FlushStartedEvent(7);
      expect(event.pendingCount, 7);
    });

    test('FlushCompletedEvent holds succeeded and dropped counts', () {
      const event = FlushCompletedEvent(succeeded: 3, dropped: 1);
      expect(event.succeeded, 3);
      expect(event.dropped, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // OfflineQueue — enqueue
  // ---------------------------------------------------------------------------

  group('OfflineQueue.enqueue', () {
    test('pendingCount increases after enqueue', () async {
      await OfflineQueue.instance.initialize(executor: (_) async {});
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r1'));
      expect(OfflineQueue.instance.pendingCount, 1);
    });

    test('emits RequestEnqueuedEvent', () async {
      final events = <OfflineQueueEvent>[];
      await OfflineQueue.instance.initialize(executor: (_) async {});
      OfflineQueue.instance.events.listen(events.add);

      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r1'));

      expect(events, hasLength(1));
      expect(events.first, isA<RequestEnqueuedEvent>());
      expect((events.first as RequestEnqueuedEvent).request.id, 'r1');
    });

    test('multiple enqueues accumulate correctly', () async {
      await OfflineQueue.instance.initialize(executor: (_) async {});
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r1'));
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r2'));
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r3'));
      expect(OfflineQueue.instance.pendingCount, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // OfflineQueue — flush
  // ---------------------------------------------------------------------------

  group('OfflineQueue.flush', () {
    test('successfully executed requests are removed from queue', () async {
      final executed = <String>[];
      await OfflineQueue.instance.initialize(
        executor: (req) async => executed.add(req.id),
      );

      ConnectivityMonitor.instance.injectStatusForTesting(true);
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r1'));
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r2'));

      // Reset so flush doesn't see "already online" auto-flush from enqueue.
      await OfflineQueue.instance.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      executed.clear();

      await OfflineQueue.instance.initialize(
        executor: (req) async => executed.add(req.id),
      );
      ConnectivityMonitor.instance.injectStatusForTesting(true);
      await OfflineQueue.instance.enqueue(_makeRequest(id: 'rx'));

      // After online enqueue, flush is triggered automatically.
      expect(OfflineQueue.instance.pendingCount, 0);
      expect(executed, contains('rx'));
    });

    test('flush is a no-op when queue is empty', () async {
      final events = <OfflineQueueEvent>[];
      await OfflineQueue.instance.initialize(executor: (_) async {});
      OfflineQueue.instance.events.listen(events.add);

      await OfflineQueue.instance.flush();

      expect(events, isEmpty);
    });

    test('flush before initialize logs warning and returns early', () async {
      // No initialize call — flush should not throw.
      await expectLater(OfflineQueue.instance.flush(), completes);
    });

    test('emits FlushStartedEvent and FlushCompletedEvent', () async {
      final events = <OfflineQueueEvent>[];

      ConnectivityMonitor.instance.injectStatusForTesting(false);
      await OfflineQueue.instance.initialize(executor: (_) async {});
      OfflineQueue.instance.events.listen(events.add);

      await OfflineQueue.instance.enqueue(_makeRequest(id: 'r1'));
      events.clear(); // discard enqueue event

      ConnectivityMonitor.instance.injectStatusForTesting(true);
      await OfflineQueue.instance.flush();

      final types = events.map((e) => e.runtimeType).toList();
      expect(types, contains(FlushStartedEvent));
      expect(types, contains(FlushCompletedEvent));
    });

    test(
      'request exceeding maxRetries is dropped and emits RequestDroppedEvent',
      () async {
        final droppedEvents = <RequestDroppedEvent>[];

        await OfflineQueue.instance.initialize(
          executor: (_) async => throw Exception('always fails'),
        );
        OfflineQueue.instance.events.whereType<RequestDroppedEvent>().listen(
          droppedEvents.add,
        );

        // retryCount already at maxRetries so next failure drops it.
        final req = _makeRequest(maxRetries: 0, retryCount: 0);
        ConnectivityMonitor.instance.injectStatusForTesting(false);
        await OfflineQueue.instance.enqueue(req);

        ConnectivityMonitor.instance.injectStatusForTesting(true);
        await OfflineQueue.instance.flush();

        expect(droppedEvents, isNotEmpty);
        expect(OfflineQueue.instance.pendingCount, 0);
      },
    );

    test(
      'FlushCompletedEvent reports correct succeeded/dropped counts',
      () async {
        FlushCompletedEvent? completedEvent;
        int callCount = 0;

        ConnectivityMonitor.instance.injectStatusForTesting(false);
        await OfflineQueue.instance.initialize(
          executor: (req) async {
            callCount++;
            if (req.id == 'fail') throw Exception('nope');
          },
        );

        OfflineQueue.instance.events.whereType<FlushCompletedEvent>().listen(
          (e) => completedEvent = e,
        );

        await OfflineQueue.instance.enqueue(
          _makeRequest(id: 'ok', maxRetries: 0),
        );
        await OfflineQueue.instance.enqueue(
          _makeRequest(id: 'fail', maxRetries: 0),
        );

        ConnectivityMonitor.instance.injectStatusForTesting(true);
        await OfflineQueue.instance.flush();

        expect(completedEvent, isNotNull);
        expect(completedEvent!.succeeded, 1);
        expect(completedEvent!.dropped, 1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // OfflineQueue — resetForTesting
  // ---------------------------------------------------------------------------

  group('OfflineQueue.resetForTesting', () {
    test('clears queue and resets state', () async {
      await OfflineQueue.instance.initialize(executor: (_) async {});
      await OfflineQueue.instance.enqueue(_makeRequest());

      await OfflineQueue.instance.resetForTesting();

      expect(OfflineQueue.instance.pendingCount, 0);
    });
  });
}
