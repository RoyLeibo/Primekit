# Changelog

## [1.1.0] — 2026-03-07

### New modules
- **ai**: `AiProvider` interface, `OpenAiProvider` (OpenAI Chat Completions), `AnthropicProvider` (Anthropic Messages API), `AiService` singleton with `configure()`
- **device/location**: `LocationService` singleton — GPS + Nominatim reverse-geocoding; `PkLocationResult` value class

### Dependency upgrades
- `geolocator`: ^13.0.0 → ^14.0.0
- `flutter_local_notifications`: ^20.1.0 → ^21.0.0

## [1.0.0] — 2026-03-07

Breaking change: Firebase adapters moved to `primekit_firebase`. Riverpod integration moved to `primekit_riverpod`.

### New modules
- **design_system**: `PkSpacing`, `PkRadius`, `PkAvatar`, `PkBadge`
- **calendar**: `CalendarEvent`, `CalendarProvider`, `CalendarService`

### Enhancements
- **ui**: `PkUiTheme` extension replaces all hardcoded colors in toast, overlay, skeleton
- **notifications**: `NotificationPreferences` for per-user notification settings
- **sync**: `PkSyncStatus` enum with human-readable label extension
- **forms**: `.matches(RegExp)`, `.noWhitespace()`, `.alphanumeric()` on `PkStringSchema`; `.refine()` on `PkObjectSchema`
- **async_state**: `_operationId` counter prevents stale-state race conditions

### Migration from primekit ^0.x
- Add `primekit_firebase` if you use any Firebase adapters
- Add `primekit_riverpod` if you use Riverpod integration
- Firebase adapter imports change from `package:primekit/src/crash/firebase_crash_reporter.dart` → `package:primekit_firebase/primekit_firebase.dart`
