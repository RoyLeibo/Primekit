/// Storage — Secure preferences, JSON cache, app settings, data migrations,
/// and local file caching.
///
/// Import this barrel to access the full Storage module:
/// ```dart
/// import 'package:primekit/src/storage/storage.dart';
/// ```
library primekit_storage;

export 'app_preferences.dart' show AppPreferences;
export 'file_cache.dart' show FileCache;
export 'json_cache.dart' show JsonCache;
export 'migration_runner.dart'
    show
        Migration,
        MigrationRecord,
        MigrationRunner,
        MigrationStore,
        SharedPrefsMigrationStore;
export 'secure_prefs.dart' show SecurePrefs, SecurePrefsBase;
