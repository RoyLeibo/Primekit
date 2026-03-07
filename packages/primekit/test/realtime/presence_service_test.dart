import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/realtime/presence_service.dart';

// ---------------------------------------------------------------------------
// In-memory stub implementation for unit testing
// ---------------------------------------------------------------------------

/// In-memory [PresenceService] for testing without Firebase.
class _InMemoryPresenceService extends PresenceService {
  final Map<String, Map<String, PresenceRecord>> _store = {};
  final Map<String, StreamController<List<PresenceRecord>>> _controllers = {};

  @override
  Future<void> connect({
    required String userId,
    required String channelId,
    Map<String, dynamic>? metadata,
    String? displayName,
  }) async {
    _store.putIfAbsent(channelId, () => {});
    _store[channelId]![userId] = PresenceRecord(
      userId: userId,
      displayName: displayName,
      lastSeen: DateTime.now(),
      isOnline: true,
      metadata: metadata,
    );
    _notify(channelId);
  }

  @override
  Future<void> disconnect({
    required String userId,
    required String channelId,
  }) async {
    final channel = _store[channelId];
    if (channel == null) {
      return;
    }
    final existing = channel[userId];
    if (existing == null) {
      return;
    }
    channel[userId] = PresenceRecord(
      userId: existing.userId,
      displayName: existing.displayName,
      lastSeen: DateTime.now(),
      isOnline: false,
      metadata: existing.metadata,
    );
    _notify(channelId);
  }

  @override
  Stream<List<PresenceRecord>> watchPresence({required String channelId}) {
    _controllers.putIfAbsent(
      channelId,
      StreamController<List<PresenceRecord>>.broadcast,
    );
    return _controllers[channelId]!.stream;
  }

  @override
  Future<List<PresenceRecord>> getOnlineUsers({
    required String channelId,
  }) async =>
      (_store[channelId]?.values ?? []).where((r) => r.isOnline).toList();

  void _notify(String channelId) {
    if (!_controllers.containsKey(channelId)) {
      return;
    }
    final online = (_store[channelId]?.values ?? [])
        .where((r) => r.isOnline)
        .toList();
    _controllers[channelId]!.add(online);
  }

  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
    _controllers.clear();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _InMemoryPresenceService service;

  setUp(() {
    service = _InMemoryPresenceService();
  });

  tearDown(() => service.dispose());

  group('PresenceService', () {
    test('connect marks user isOnline=true', () async {
      await service.connect(userId: 'user1', channelId: 'room1');

      final users = await service.getOnlineUsers(channelId: 'room1');
      expect(users.length, equals(1));
      expect(users.first.userId, equals('user1'));
      expect(users.first.isOnline, isTrue);
    });

    test('disconnect marks user isOnline=false', () async {
      await service.connect(userId: 'user1', channelId: 'room1');
      await service.disconnect(userId: 'user1', channelId: 'room1');

      final users = await service.getOnlineUsers(channelId: 'room1');
      expect(users, isEmpty);
    });

    test('multiple users can be online simultaneously', () async {
      await service.connect(userId: 'user1', channelId: 'room1');
      await service.connect(userId: 'user2', channelId: 'room1');
      await service.connect(userId: 'user3', channelId: 'room1');

      final users = await service.getOnlineUsers(channelId: 'room1');
      expect(users.length, equals(3));
    });

    test('disconnect one user leaves others online', () async {
      await service.connect(userId: 'user1', channelId: 'room1');
      await service.connect(userId: 'user2', channelId: 'room1');
      await service.disconnect(userId: 'user1', channelId: 'room1');

      final users = await service.getOnlineUsers(channelId: 'room1');
      expect(users.length, equals(1));
      expect(users.first.userId, equals('user2'));
    });

    test('watchPresence emits after connect', () async {
      final emitted = <List<PresenceRecord>>[];
      final sub = service.watchPresence(channelId: 'room1').listen(emitted.add);

      await service.connect(userId: 'user1', channelId: 'room1');
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      expect(emitted.last.any((r) => r.userId == 'user1'), isTrue);

      await sub.cancel();
    });

    test('watchPresence emits after disconnect', () async {
      await service.connect(userId: 'user1', channelId: 'room1');

      final emitted = <List<PresenceRecord>>[];
      final sub = service.watchPresence(channelId: 'room1').listen(emitted.add);

      await service.disconnect(userId: 'user1', channelId: 'room1');
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      expect(emitted.last, isEmpty);

      await sub.cancel();
    });

    test('displayName is preserved in PresenceRecord', () async {
      await service.connect(
        userId: 'user1',
        channelId: 'room1',
        displayName: 'Alice',
      );

      final users = await service.getOnlineUsers(channelId: 'room1');
      expect(users.first.displayName, equals('Alice'));
    });

    test('metadata is preserved in PresenceRecord', () async {
      await service.connect(
        userId: 'user1',
        channelId: 'room1',
        metadata: {'role': 'admin'},
      );

      final users = await service.getOnlineUsers(channelId: 'room1');
      expect(users.first.metadata?['role'], equals('admin'));
    });

    test('getOnlineUsers on empty channel returns empty list', () async {
      final users = await service.getOnlineUsers(channelId: 'empty-room');
      expect(users, isEmpty);
    });

    test('channels are isolated', () async {
      await service.connect(userId: 'user1', channelId: 'room1');
      await service.connect(userId: 'user2', channelId: 'room2');

      final room1 = await service.getOnlineUsers(channelId: 'room1');
      final room2 = await service.getOnlineUsers(channelId: 'room2');

      expect(room1.length, equals(1));
      expect(room1.first.userId, equals('user1'));
      expect(room2.length, equals(1));
      expect(room2.first.userId, equals('user2'));
    });
  });

  group('PresenceRecord', () {
    test('equality based on userId and isOnline', () {
      const r1 = PresenceRecord(
        userId: 'u1',
        lastSeen: _fixedTime,
        isOnline: true,
      );
      const r2 = PresenceRecord(
        userId: 'u1',
        lastSeen: _fixedTime,
        isOnline: true,
      );
      const r3 = PresenceRecord(
        userId: 'u1',
        lastSeen: _fixedTime,
        isOnline: false,
      );

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });

    test('toString includes userId and isOnline', () {
      const record = PresenceRecord(
        userId: 'alice',
        lastSeen: _fixedTime,
        isOnline: true,
      );
      expect(record.toString(), contains('alice'));
      expect(record.toString(), contains('true'));
    });
  });
}

const _fixedTime = _ConstDateTime();

class _ConstDateTime implements DateTime {
  const _ConstDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime(2024);
}
