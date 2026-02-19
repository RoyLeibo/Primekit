import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

// ---------------------------------------------------------------------------
// Migration contract
// ---------------------------------------------------------------------------

/// Represents a single versioned data migration.
///
/// Implement [up] to apply the migration. Implement [down] to roll it back
/// (optional — a default no-op is provided).
abstract class Migration {
  /// The monotonically increasing version number for this migration.
  ///
  /// Migrations are executed in ascending [version] order. Gaps are allowed.
  int get version;

  /// A human-readable description shown in logs and stored in the migration
  /// record.
  String get description;

  /// Applies this migration.
  ///
  /// Throw any exception to abort; the runner will propagate the error and
  /// stop execution.
  Future<void> up();

  /// Rolls back this migration.
  ///
  /// Defaults to a no-op. Override when you need reversibility.
  Future<void> down() async {}
}

// ---------------------------------------------------------------------------
// Migration record
// ---------------------------------------------------------------------------

/// An immutable record of a migration that has been applied.
final class MigrationRecord {
  const MigrationRecord({
    required this.version,
    required this.description,
    required this.appliedAt,
  });

  factory MigrationRecord.fromJson(Map<String, dynamic> json) =>
      MigrationRecord(
        version: json['version'] as int,
        description: json['description'] as String,
        appliedAt: DateTime.parse(json['appliedAt'] as String),
      );

  /// The version number of the applied migration.
  final int version;

  /// Description provided by the [Migration].
  final String description;

  /// UTC timestamp when this migration was applied.
  final DateTime appliedAt;

  Map<String, dynamic> toJson() => {
        'version': version,
        'description': description,
        'appliedAt': appliedAt.toIso8601String(),
      };

  @override
  String toString() =>
      'MigrationRecord(v$version: "$description" '
      'at ${appliedAt.toIso8601String()})';
}

// ---------------------------------------------------------------------------
// MigrationStore
// ---------------------------------------------------------------------------

/// Persists the list of executed [MigrationRecord]s.
///
/// Backed by [SharedPreferences] by default. Override for custom backends.
abstract class MigrationStore {
  /// Returns all previously applied migration records.
  Future<List<MigrationRecord>> loadRecords();

  /// Appends [record] to the stored list.
  Future<void> appendRecord(MigrationRecord record);
}

/// The default [MigrationStore] backed by [SharedPreferences].
final class SharedPrefsMigrationStore implements MigrationStore {
  static const String _key = 'pk_migration_records';

  @override
  Future<List<MigrationRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(MigrationRecord.fromJson)
          .toList(growable: false);
    } on Exception catch (e) {
      PrimekitLogger.warning(
        'Could not parse stored migration records; treating as empty',
        tag: 'MigrationRunner',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<void> appendRecord(MigrationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadRecords();
    final updated = [...existing, record];
    await prefs.setString(_key, jsonEncode(updated.map((r) => r.toJson()).toList()));
  }
}

// ---------------------------------------------------------------------------
// MigrationRunner
// ---------------------------------------------------------------------------

/// Runs pending data migrations in version order.
///
/// On each [run] call the runner:
/// 1. Loads applied migration records from [store].
/// 2. Filters [migrations] to those not yet applied (by version).
/// 3. Sorts pending migrations by ascending version.
/// 4. Executes each migration's [Migration.up] method sequentially.
/// 5. Appends a [MigrationRecord] after each successful migration.
///
/// If any migration throws, execution halts and the error is rethrown as a
/// [StorageException]. Migrations already applied before the failure are
/// retained in the store.
///
/// ```dart
/// final runner = MigrationRunner(
///   migrations: [
///     AddUserTableMigration(),    // version: 1
///     AddEmailIndexMigration(),   // version: 2
///   ],
///   store: SharedPrefsMigrationStore(),
/// );
///
/// await runner.run(); // runs pending migrations on app startup
/// ```
final class MigrationRunner {
  MigrationRunner({
    required List<Migration> migrations,
    MigrationStore? store,
  })  : _migrations = List.unmodifiable(migrations),
        _store = store ?? SharedPrefsMigrationStore();

  final List<Migration> _migrations;
  final MigrationStore _store;

  // ---------------------------------------------------------------------------
  // Run
  // ---------------------------------------------------------------------------

  /// Executes all pending migrations in ascending [Migration.version] order.
  ///
  /// Throws [StorageException] if a migration fails.
  Future<void> run() async {
    final applied = await _store.loadRecords();
    final appliedVersions = applied.map((r) => r.version).toSet();

    final pending = _migrations
        .where((m) => !appliedVersions.contains(m.version))
        .toList(growable: false)
      ..sort((a, b) => a.version.compareTo(b.version));

    if (pending.isEmpty) {
      PrimekitLogger.info('No pending migrations', tag: 'MigrationRunner');
      return;
    }

    PrimekitLogger.info(
      'Running ${pending.length} migration(s)',
      tag: 'MigrationRunner',
    );

    for (final migration in pending) {
      await _runOne(migration);
    }

    PrimekitLogger.info(
      'All migrations completed. Current version: ${await currentVersion}',
      tag: 'MigrationRunner',
    );
  }

  // ---------------------------------------------------------------------------
  // Introspection
  // ---------------------------------------------------------------------------

  /// Returns the version number of the most recently applied migration, or
  /// `0` if no migrations have been applied.
  Future<int> get currentVersion async {
    final records = await _store.loadRecords();
    if (records.isEmpty) return 0;
    return records
        .map((r) => r.version)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Returns an immutable list of all applied [MigrationRecord]s.
  Future<List<MigrationRecord>> get executedMigrations =>
      _store.loadRecords();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _runOne(Migration migration) async {
    PrimekitLogger.info(
      'Applying migration v${migration.version}: "${migration.description}"',
      tag: 'MigrationRunner',
    );
    try {
      await migration.up();

      final record = MigrationRecord(
        version: migration.version,
        description: migration.description,
        appliedAt: DateTime.now().toUtc(),
      );
      await _store.appendRecord(record);

      PrimekitLogger.info(
        'Migration v${migration.version} applied successfully',
        tag: 'MigrationRunner',
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'Migration v${migration.version} failed: "${migration.description}"',
        tag: 'MigrationRunner',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message:
            'Migration v${migration.version} ("${migration.description}") failed',
        code: 'MIGRATION_FAILED',
        cause: e,
      );
    }
  }
}
