# flags — Feature Flags

**Purpose:** Feature flag management with local caching and multiple backends.

**Key exports:**
- `FlagService` — singleton; check flags with `.isEnabled(flagKey)`
- `FlagProvider` — abstract backend interface
- `FeatureFlag` — value type with `enabled`, `rolloutPercentage`
- `FlagCache` — persistent caching (survives restarts)
- `LocalFlagProvider` — hardcoded flags for testing
- `FirebaseFlagProvider` — Firebase Remote Config backend (import via `firebase.dart`)
- `MongoFlagProvider` — MongoDB backend

**Pattern:** Remote flags with local cache fallback. Cache survives app restart.

**Planned flags (all 4 apps):**
`ai_enabled`, `billing_enabled`, `rbac_enabled`, `realtime_sync_enabled`, `audit_log_enabled`

**Dependencies:** `core`, `storage`

**Maintenance:** Update when new provider added. Keep planned flags list current.
