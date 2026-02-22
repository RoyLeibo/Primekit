import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/realtime/message_buffer.dart';
import 'package:primekit/src/realtime/realtime_channel.dart';
import 'package:primekit/src/realtime/websocket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// In-memory MessageBuffer stub that avoids SharedPreferences in tests.
class _FakeMessageBuffer extends Fake implements MessageBuffer {
  final List<Map<String, dynamic>> _queued = [];
  final List<String?> _queuedTypes = [];

  @override
  Future<void> enqueue(Map<String, dynamic> payload, {String? type}) async {
    _queued.add(payload);
    _queuedTypes.add(type);
  }

  @override
  Future<List<BufferedMessage>> dequeueAll() async {
    final msgs = List<BufferedMessage>.generate(
      _queued.length,
      (i) => BufferedMessage(
        id: 'buf-$i',
        type: _queuedTypes[i],
        payload: _queued[i],
        queuedAt: DateTime.now(),
      ),
    );
    _queued.clear();
    _queuedTypes.clear();
    return msgs;
  }

  @override
  Future<int> get size async => _queued.length;

  @override
  Future<void> clear() async {
    _queued.clear();
    _queuedTypes.clear();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PkWebSocketChannel', () {
    late _FakeMessageBuffer fakeBuffer;
    late PkWebSocketChannel channel;

    setUp(() {
      fakeBuffer = _FakeMessageBuffer();
      channel = PkWebSocketChannel(
        uri: Uri.parse('ws://localhost:9999'),
        channelId: 'test-channel',
        reconnectDelay: const Duration(milliseconds: 50),
        maxReconnectAttempts: 1,
        pingInterval: const Duration(hours: 1),
        connectTimeout: const Duration(milliseconds: 100),
        messageBuffer: fakeBuffer,
      );
    });

    tearDown(() async {
      await channel.dispose();
    });

    test('initial state is disconnected', () {
      expect(channel.isConnected, isFalse);
      expect(channel.channelId, equals('test-channel'));
    });

    test('status and messages streams are broadcast', () {
      expect(channel.status.isBroadcast, isTrue);
      expect(channel.messages.isBroadcast, isTrue);
    });

    test('send while disconnected enqueues to buffer', () async {
      await channel.send({'text': 'hello'}, type: 'chat');
      expect(await fakeBuffer.size, equals(1));
    });

    test('send without type enqueues with null type', () async {
      await channel.send({'text': 'no type'});
      expect(await fakeBuffer.size, equals(1));
    });

    test('multiple send calls while disconnected all enqueue', () async {
      await channel.send({'n': 1});
      await channel.send({'n': 2});
      await channel.send({'n': 3});
      expect(await fakeBuffer.size, equals(3));
    });

    test('connect emits ChannelStatus.connecting first', () async {
      final statuses = <ChannelStatus>[];
      final sub = channel.status.listen(statuses.add);
      unawaited(channel.connect());
      await Future<void>.delayed(Duration.zero);
      expect(statuses, contains(ChannelStatus.connecting));
      await sub.cancel();
    });

    test('connect to bad URI -> eventually non-connected status', () async {
      final statuses = <ChannelStatus>[];
      final sub = channel.status.listen(statuses.add);
      unawaited(channel.connect());
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        statuses,
        anyOf(
          contains(ChannelStatus.error),
          contains(ChannelStatus.reconnecting),
          contains(ChannelStatus.disconnected),
        ),
      );
      await sub.cancel();
    }, timeout: const Timeout(Duration(seconds: 5)),);

    test('disconnect without prior connect emits disconnected', () async {
      final statuses = <ChannelStatus>[];
      final sub = channel.status.listen(statuses.add);
      // Disconnect from initial state — should emit disconnecting then
      // disconnected.
      await channel.disconnect();
      // Allow microtasks to flush so stream events are delivered.
      await Future<void>.delayed(Duration.zero);
      expect(statuses, contains(ChannelStatus.disconnected));
      await sub.cancel();
    });
  });

  group('MessageBuffer', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      SharedPreferences.setMockInitialValues({});
    });

    MessageBuffer makeBuffer([int? maxSize]) {
      final id = DateTime.now().microsecondsSinceEpoch;
      return maxSize != null
          ? MessageBuffer(channelId: 'buf-$id', maxSize: maxSize)
          : MessageBuffer(channelId: 'buf-$id');
    }

    test('starts empty', () async {
      final buffer = makeBuffer();
      expect(await buffer.size, equals(0));
    });

    test('enqueue increases size', () async {
      final buffer = makeBuffer();
      await buffer.enqueue({'a': 1});
      expect(await buffer.size, equals(1));
    });

    test('dequeueAll returns FIFO order', () async {
      final buffer = makeBuffer();
      await buffer.enqueue({'seq': 1}, type: 'a');
      await buffer.enqueue({'seq': 2}, type: 'b');
      await buffer.enqueue({'seq': 3}, type: 'c');
      final msgs = await buffer.dequeueAll();
      expect(msgs.length, equals(3));
      expect(msgs[0].payload['seq'], equals(1));
      expect(msgs[1].payload['seq'], equals(2));
      expect(msgs[2].payload['seq'], equals(3));
    });

    test('dequeueAll clears the buffer', () async {
      final buffer = makeBuffer();
      await buffer.enqueue({'x': 42});
      await buffer.dequeueAll();
      expect(await buffer.size, equals(0));
    });

    test('dequeueAll on empty buffer returns empty list', () async {
      final buffer = makeBuffer();
      expect(await buffer.dequeueAll(), isEmpty);
    });

    test('type is preserved through enqueue/dequeue', () async {
      final buffer = makeBuffer();
      await buffer.enqueue({'data': 'hello'}, type: 'chat');
      final msgs = await buffer.dequeueAll();
      expect(msgs.first.type, equals('chat'));
    });

    test('null type is preserved', () async {
      final buffer = makeBuffer();
      await buffer.enqueue({'data': 'no type'});
      final msgs = await buffer.dequeueAll();
      expect(msgs.first.type, isNull);
    });

    test('respects maxSize by evicting oldest', () async {
      final buffer = makeBuffer(3);
      await buffer.enqueue({'seq': 1});
      await buffer.enqueue({'seq': 2});
      await buffer.enqueue({'seq': 3});
      await buffer.enqueue({'seq': 4});
      final msgs = await buffer.dequeueAll();
      expect(msgs.length, equals(3));
      expect(msgs.map((m) => m.payload['seq']), equals([2, 3, 4]));
    });

    test('clear empties the buffer', () async {
      final buffer = makeBuffer();
      await buffer.enqueue({'a': 1});
      await buffer.enqueue({'b': 2});
      await buffer.clear();
      expect(await buffer.size, equals(0));
    });
  });

  group('RealtimeMessage', () {
    final fixedTime = DateTime(2024);

    test('equality is based on id', () {
      final msg1 =
          RealtimeMessage(id: 'abc', payload: const {}, receivedAt: fixedTime);
      final msg2 = RealtimeMessage(
        id: 'abc',
        payload: const {'extra': true},
        receivedAt: fixedTime,
      );
      final msg3 =
          RealtimeMessage(id: 'def', payload: const {}, receivedAt: fixedTime);
      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString includes id and type', () {
      final msg = RealtimeMessage(
        id: 'xyz',
        type: 'chat',
        payload: const {},
        receivedAt: fixedTime,
      );
      expect(msg.toString(), contains('xyz'));
      expect(msg.toString(), contains('chat'));
    });
  });
}
