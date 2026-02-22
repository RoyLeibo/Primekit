import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/sync/conflict_resolver.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _doc({
  String id = 'doc-1',
  String updatedAt = '2024-01-01T00:00:00.000Z',
  String value = 'value',
}) =>
    {'id': id, 'updatedAt': updatedAt, 'value': value};

void main() {
  // -------------------------------------------------------------------------
  // LastWriteWinsResolver
  // -------------------------------------------------------------------------

  group('LastWriteWinsResolver', () {
    const resolver = LastWriteWinsResolver<Map<String, dynamic>>();

    test('local is newer → local wins', () async {
      final local = _doc(updatedAt: '2024-06-01T12:00:00.000Z', value: 'local');
      final remote = _doc(updatedAt: '2024-01-01T00:00:00.000Z', value: 'remote');

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'local');
    });

    test('remote is newer → remote wins', () async {
      final local = _doc(updatedAt: '2024-01-01T00:00:00.000Z', value: 'local');
      final remote =
          _doc(updatedAt: '2024-06-01T12:00:00.000Z', value: 'remote');

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'remote');
    });

    test('equal timestamps, preferLocal=false → remote wins (default)', () async {
      final ts = '2024-03-15T09:00:00.000Z';
      final local = _doc(updatedAt: ts, value: 'local');
      final remote = _doc(updatedAt: ts, value: 'remote');

      const defaultResolver = LastWriteWinsResolver<Map<String, dynamic>>();
      final result =
          await defaultResolver.resolve(local: local, remote: remote);
      expect(result['value'], 'remote');
    });

    test('equal timestamps, preferLocal=true → local wins', () async {
      final ts = '2024-03-15T09:00:00.000Z';
      final local = _doc(updatedAt: ts, value: 'local');
      final remote = _doc(updatedAt: ts, value: 'remote');

      const resolver =
          LastWriteWinsResolver<Map<String, dynamic>>(preferLocal: true);
      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'local');
    });

    test('missing updatedAt in local → remote wins', () async {
      final local = {'id': 'doc-1', 'value': 'local'};
      final remote =
          _doc(updatedAt: '2024-01-01T00:00:00.000Z', value: 'remote');

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'remote');
    });

    test('missing updatedAt in both → remote wins (both epoch)', () async {
      final local = {'id': 'doc-1', 'value': 'local'};
      final remote = {'id': 'doc-1', 'value': 'remote'};

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'remote');
    });

    test('returns full document map, not just the winning value', () async {
      final local = {
        'id': 'doc-1',
        'updatedAt': '2024-06-01T00:00:00.000Z',
        'title': 'Local title',
        'done': false,
      };
      final remote = {
        'id': 'doc-1',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'title': 'Remote title',
        'done': true,
      };

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['title'], 'Local title');
      expect(result['done'], false);
    });
  });

  // -------------------------------------------------------------------------
  // ServerWinsResolver
  // -------------------------------------------------------------------------

  group('ServerWinsResolver', () {
    const resolver = ServerWinsResolver<Map<String, dynamic>>();

    test('always returns remote regardless of timestamps', () async {
      final local =
          _doc(updatedAt: '2099-01-01T00:00:00.000Z', value: 'local');
      final remote =
          _doc(updatedAt: '2000-01-01T00:00:00.000Z', value: 'remote');

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'remote');
    });

    test('returns full remote document', () async {
      final local = {'id': 'doc-1', 'updatedAt': '2099-01-01T00:00:00.000Z', 'a': 1};
      final remote = {
        'id': 'doc-1',
        'updatedAt': '2000-01-01T00:00:00.000Z',
        'b': 2,
      };

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result.containsKey('b'), isTrue);
      expect(result.containsKey('a'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ClientWinsResolver
  // -------------------------------------------------------------------------

  group('ClientWinsResolver', () {
    const resolver = ClientWinsResolver<Map<String, dynamic>>();

    test('always returns local regardless of timestamps', () async {
      final local =
          _doc(updatedAt: '2000-01-01T00:00:00.000Z', value: 'local');
      final remote =
          _doc(updatedAt: '2099-01-01T00:00:00.000Z', value: 'remote');

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['value'], 'local');
    });

    test('returns full local document', () async {
      final local = {'id': 'doc-1', 'updatedAt': '2000-01-01T00:00:00.000Z', 'a': 1};
      final remote = {
        'id': 'doc-1',
        'updatedAt': '2099-01-01T00:00:00.000Z',
        'b': 2,
      };

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result.containsKey('a'), isTrue);
      expect(result.containsKey('b'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ManualConflictResolver
  // -------------------------------------------------------------------------

  group('ManualConflictResolver', () {
    test('invokes the onConflict callback and returns its result', () async {
      final resolver = ManualConflictResolver<Map<String, dynamic>>(
        onConflict: (local, remote) async => {'id': 'merged', 'source': 'manual'},
      );

      final result = await resolver.resolve(
        local: {'id': 'doc-1', 'value': 'local'},
        remote: {'id': 'doc-1', 'value': 'remote'},
      );

      expect(result['source'], 'manual');
    });

    test('callback receives both local and remote documents', () async {
      Map<String, dynamic>? capturedLocal;
      Map<String, dynamic>? capturedRemote;

      final resolver = ManualConflictResolver<Map<String, dynamic>>(
        onConflict: (local, remote) async {
          capturedLocal = local;
          capturedRemote = remote;
          return local;
        },
      );

      final localDoc = {'id': 'doc-1', 'value': 'local'};
      final remoteDoc = {'id': 'doc-1', 'value': 'remote'};
      await resolver.resolve(local: localDoc, remote: remoteDoc);

      expect(capturedLocal, equals(localDoc));
      expect(capturedRemote, equals(remoteDoc));
    });
  });

  // -------------------------------------------------------------------------
  // FieldMergeResolver
  // -------------------------------------------------------------------------

  group('FieldMergeResolver', () {
    const resolver = FieldMergeResolver<Map<String, dynamic>>();

    test('takes local value when local field timestamp is newer', () async {
      final local = {
        'id': 'doc-1',
        'title': 'Local title',
        '_fieldTimestamps': {
          'title': '2024-06-01T00:00:00.000Z',
        },
      };
      final remote = {
        'id': 'doc-1',
        'title': 'Remote title',
        '_fieldTimestamps': {
          'title': '2024-01-01T00:00:00.000Z',
        },
      };

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['title'], 'Local title');
    });

    test('takes remote value when remote field timestamp is newer', () async {
      final local = {
        'id': 'doc-1',
        'title': 'Local title',
        '_fieldTimestamps': {
          'title': '2024-01-01T00:00:00.000Z',
        },
      };
      final remote = {
        'id': 'doc-1',
        'title': 'Remote title',
        '_fieldTimestamps': {
          'title': '2024-06-01T00:00:00.000Z',
        },
      };

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['title'], 'Remote title');
    });

    test('merges non-overlapping fields from both documents', () async {
      final local = {
        'id': 'doc-1',
        'localField': 'local',
        '_fieldTimestamps': {
          'localField': '2024-06-01T00:00:00.000Z',
        },
      };
      final remote = {
        'id': 'doc-1',
        'remoteField': 'remote',
        '_fieldTimestamps': {
          'remoteField': '2024-06-01T00:00:00.000Z',
        },
      };

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['localField'], 'local');
      expect(result['remoteField'], 'remote');
    });

    test('field without timestamp defaults to remote', () async {
      final local = {'id': 'doc-1', 'title': 'Local'};
      final remote = {'id': 'doc-1', 'title': 'Remote'};

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result['title'], 'Remote');
    });
  });
}
