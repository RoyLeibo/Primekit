# storage — Local Data Persistence

**Purpose:** Typed wrappers for SharedPreferences, FlutterSecureStorage, Hive, and file caching.

**Key exports:**
- `AppPreferences` — singleton for common settings (theme, locale, onboarding flag)
- `SecurePrefs` — secure key/value store (FlutterSecureStorage); used by `auth` for tokens
- `JsonCache<T>` — type-safe JSON caching backed by SharedPreferences
- `MigrationRunner` — schema migration framework for versioned local storage
- `FileCache` — file-based caching (iOS/Android/Desktop only, not exported from barrel)

**Dependencies:** shared_preferences 2.3.0, flutter_secure_storage 10.0.0, hive_flutter 1.1.0

**Note:** `FileCache` is NOT exported from `storage.dart` — import directly from src path if needed.

**Maintenance:** Update when new storage backend added or migration API changes.
