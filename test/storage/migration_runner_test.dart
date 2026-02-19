import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/src/core/exceptions.dart';
import 'package:primekit/src/storage/migration_runner.dart';

// ---------------------------------------------------------------------------
// Fakes / helpers
// ---------------------------------------------------------------------------

class InMemoryMigrationStore implements MigrationStore {
  final List<MigrationRecord> _records = [];

  @override
  Future<List<MigrationRecord>> loadRecords() async =>
      List.unmodifiable(_records);

  @override
  Future<void> appendRecord(MigrationRecord record) async {
    _records.add(record);
  }

  void clear() => _records.clear();
}

class _StubMigration extends Migration {
  _StubMigration({
    required this.version,
    required this.description,
    bool shouldFail = false,
    Future<void> Function()? onUp,
  })  : _shouldFail = shouldFail,
        _onUp = onUp;

  @override
  final int version;

  @override
  final String description;

  final bool _shouldFail;
  final Future<void> Function()? _onUp;

  int upCallCount = 0;
  int downCallCount = 0;

  @override
  Future<void> up() async {
    upCallCount++;
    if (_shouldFail) throw Exception('Simulated migration failure');
    await _onUp?.call();
  }

  @override
  Future<void> down() async {
    downCallCount++;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late InMemoryMigrationStore store;

  setUp(() {
    store = InMemoryMigrationStore();
  });

  MigrationRunner makeRunner(List<Migration> migrations) =>
      MigrationRunner(migrations: migrations, store: store);

  // ---------------------------------------------------------------------------
  // run
  // ---------------------------------------------------------------------------

  group('run', () {
    test('executes all migrations when none have been applied', () async {
      final m1 = _StubMigration(version: 1, description: 'First');
      final m2 = _StubMigration(version: 2, description: 'Second');
      final runner = makeRunner([m1, m2]);

      await runner.run();

      expect(m1.upCallCount, 1);
      expect(m2.upCallCount, 1);
    });

    test('does not re-run already-applied migrations', () async {
      store.appendRecord(
        MigrationRecord(
          version: 1,
          description: 'Already done',
          appliedAt: DateTime.now().toUtc(),
        ),
      );

      final m1 = _StubMigration(version: 1, description: 'First');
      final m2 = _StubMigration(version: 2, description: 'Second');
      final runner = makeRunner([m1, m2]);

      await runner.run();

      expect(m1.upCallCount, 0);
      expect(m2.upCallCount, 1);
    });

    test('runs migrations in ascending version order regardless of list order',
        () async {
      final callOrder = <int>[];
      final m3 = _StubMigration(
        version: 3,
        description: 'Third',
        onUp: () async => callOrder.add(3),
      );
      final m1 = _StubMigration(
        version: 1,
        description: 'First',
        onUp: () async => callOrder.add(1),
      );
      final m2 = _StubMigration(
        version: 2,
        description: 'Second',
        onUp: () async => callOrder.add(2),
      );

      final runner = makeRunner([m3, m1, m2]);
      await runner.run();

      expect(callOrder, [1, 2, 3]);
    });

    test('records applied migrations in the store', () async {
      final m1 = _StubMigration(version: 1, description: 'Alpha');
      final m2 = _StubMigration(version: 2, description: 'Beta');
      final runner = makeRunner([m1, m2]);

      await runner.run();
      final records = await store.loadRecords();

      expect(records.length, 2);
      expect(records[0].version, 1);
      expect(records[0].description, 'Alpha');
      expect(records[1].version, 2);
      expect(records[1].description, 'Beta');
    });

    test('is a no-op when no migrations are pending', () async {
      store.appendRecord(
        MigrationRecord(
          version: 1,
          description: 'Done',
          appliedAt: DateTime.now().toUtc(),
        ),
      );
      final m1 = _StubMigration(version: 1, description: 'Done');
      final runner = makeRunner([m1]);

      await runner.run();

      expect(m1.upCallCount, 0);
    });

    test('throws StorageException when a migration fails', () async {
      final m1 = _StubMigration(version: 1, description: 'Good');
      final m2 = _StubMigration(
        version: 2,
        description: 'Bad',
        shouldFail: true,
      );
      final runner = makeRunner([m1, m2]);

      await expectLater(
        runner.run,
        throwsA(isA<StorageException>()),
      );
    });

    test('retains records for migrations that succeeded before a failure',
        () async {
      final m1 = _StubMigration(version: 1, description: 'Good');
      final m2 = _StubMigration(
        version: 2,
        description: 'Bad',
        shouldFail: true,
      );
      final runner = makeRunner([m1, m2]);

      try {
        await runner.run();
      } catch (_) {}

      final records = await store.loadRecords();
      expect(records.length, 1);
      expect(records.first.version, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // currentVersion
  // ---------------------------------------------------------------------------

  group('currentVersion', () {
    test('returns 0 when no migrations applied', () async {
      final runner = makeRunner([]);
      expect(await runner.currentVersion, 0);
    });

    test('returns the highest applied version', () async {
      store.appendRecord(
        MigrationRecord(version: 1, description: 'v1', appliedAt: DateTime.now().toUtc()),
      );
      store.appendRecord(
        MigrationRecord(version: 3, description: 'v3', appliedAt: DateTime.now().toUtc()),
      );
      store.appendRecord(
        MigrationRecord(version: 2, description: 'v2', appliedAt: DateTime.now().toUtc()),
      );

      final runner = makeRunner([]);
      expect(await runner.currentVersion, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // executedMigrations
  // ---------------------------------------------------------------------------

  group('executedMigrations', () {
    test('returns empty list before any migrations run', () async {
      final runner = makeRunner([]);
      expect(await runner.executedMigrations, isEmpty);
    });

    test('returns all applied records', () async {
      final m1 = _StubMigration(version: 1, description: 'One');
      final m2 = _StubMigration(version: 2, description: 'Two');
      final runner = makeRunner([m1, m2]);

      await runner.run();
      final executed = await runner.executedMigrations;

      expect(executed.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // MigrationRecord
  // ---------------------------------------------------------------------------

  group('MigrationRecord', () {
    test('serialises and deserialises via toJson / fromJson', () {
      final now = DateTime.now().toUtc();
      final record = MigrationRecord(
        version: 5,
        description: 'Test migration',
        appliedAt: now,
      );

      final json = record.toJson();
      final restored = MigrationRecord.fromJson(json);

      expect(restored.version, record.version);
      expect(restored.description, record.description);
      expect(
        restored.appliedAt.toIso8601String(),
        record.appliedAt.toIso8601String(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Migration.down (optional rollback)
  // ---------------------------------------------------------------------------

  group('Migration.down', () {
    test('down is callable and defaults to no-op', () async {
      final m = _StubMigration(version: 1, description: 'Reversible');
      await expectLater(m.down(), completes);
      expect(m.downCallCount, 1);
    });
  });
}
