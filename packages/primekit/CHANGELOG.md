# Changelog

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
