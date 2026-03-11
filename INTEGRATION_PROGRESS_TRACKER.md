# PrimeKit Integration — Work Progress Tracker

_Last updated: 2026-03-10_

> **Full implementation plan:** see [`INTEGRATION_PLAN.md`](./INTEGRATION_PLAN.md)

---

## Quick Wins (PawTrack wrapper deletions)

| Task | Status | Notes |
|------|--------|-------|
| Delete `core/widgets/confirmation_dialog.dart` | ✅ Already gone | Never existed / already cleaned up |
| Delete `core/widgets/empty_state_widget.dart` | ✅ Already gone | Never existed / already cleaned up |
| Delete `core/widgets/loading_shimmer.dart` | ✅ Already gone | Never existed / already cleaned up |

---

## Blocker — Bullseye Riverpod 2.x → 3.x Migration

| Task | Status | Notes |
|------|--------|-------|
| `auth_provider.dart` — `StateNotifier` → `AsyncNotifier` | ✅ Done | |
| `groups_provider.dart` — `CreateGroupNotifier StateNotifier` → `AsyncNotifier` | ✅ Done | |
| `matches_provider.dart` — `StateNotifier` + factory → `AutoDisposeFamilyNotifier` | ✅ Done | |
| `matches_screen.dart:153` — `.valueOrNull` → `.value` | ✅ Done | |
| `scoring_info_sheet.dart:55` — `.valueOrNull` → `.value` | ✅ Done | |
| `home_screen.dart:233,361,431` — `.valueOrNull` → `.value` | ✅ Done | |

---

## Phase 3 — Value-Add Features

| Feature | Apps | PrimeKit Module | Status | Notes |
|---------|------|----------------|--------|-------|
| Billing + Membership | Bullseye, best_todo_list | `billing.dart`, `membership.dart` | ⏳ Deferred | Skipped per user request |
| Analytics + funnels | All 4 | `analytics.dart` | ✅ Done | EventTracker + DebugAnalyticsProvider wired; key events instrumented in all 4 apps |
| Feature flags | All 4 | `flags.dart` | ⏳ Deferred | Skipped per user request |
| RBAC (group admin/member roles) | Splitly, Bullseye | `rbac.dart` | ✅ Done | Policy defined; RbacProvider implemented; RbacGate on admin-only actions |
| Forms validation | PawTrack | `forms.dart` | ✅ Done | 5 form screens migrated to PkSchema validators |

---

## PrimeKit Gaps — Built

| Gap | Priority | Status | Files Added |
|-----|---------|--------|-------------|
| `FirebaseAuthInterceptor` | High | ✅ Done | `src/auth/firebase_auth_interceptor.dart`; exported from `auth.dart` |
| `RemoteNotificationPreferences` | Medium | ✅ Done | `src/notifications/remote_notification_preferences.dart`; exported from `notifications.dart` |
| `SyncStatusMonitor` | Medium | ✅ Done | `src/network/sync_status_monitor.dart`; exported from `network.dart` |
| Audit Log module | High | ✅ Done | New `src/audit/` module — see breakdown below |
| Design System (`PkColorScheme` + `PkTypography`) | High | ✅ Done | `src/design_system/pk_color_scheme.dart`, `pk_typography.dart`; exported from `design_system.dart` |
| `GoogleCalendarProvider` | Medium | ✅ Done | `src/calendar/google_calendar_provider.dart`; exported from `calendar.dart`; `googleapis: ^13.0.0` added to pubspec |

---

## PrimeKit Gaps — Still Pending

_None — all gaps complete._

---

## PrimeKit 2.2.0 — Added

| Addition | Status | Notes |
|----------|--------|-------|
| `DebugAnalyticsProvider` | ✅ Published | `src/analytics/debug_analytics_provider.dart`; exported from `analytics.dart`. Published 2026-03-11. |

All 4 apps currently use `primekit: ^2.1.0` with `dependency_overrides: primekit: path: ../Primekit` until pub.dev indexes 2.2.0.

**TODO (once 2.2.0 indexed):** Update all 4 apps to `primekit: ^2.2.0` and remove the `dependency_overrides` block from each `pubspec.yaml`.

---

## PrimeKit Gaps — Design System (detail)

**`pk_color_scheme.dart`** — Semantic token set → Flutter `ColorScheme` / `ThemeData`
- `PkColorScheme(primary, onPrimary, secondary, surface, onSurface, error, outline, ...)`
- `PkColorScheme.light(...)` / `.dark(...)` — Material 3 defaults, fully overridable
- `.toColorScheme()` → Flutter `ColorScheme`
- `.toThemeData({PkTypography?})` → complete `ThemeData` with M3 enabled

**`pk_typography.dart`** — Font-family-injectable text scale
- `PkTypography({fontFamily, displayFontFamily, letterSpacingScale})`
- 15 named styles: `displayLg/Md/Sm`, `headingLg/Md/Sm`, `titleLg/Md/Sm`, `bodyLg/Md/Sm`, `labelLg/Md/Sm`
- `.toTextTheme(colorScheme)` → Material 3 `TextTheme` with correct foreground colours

**How each app maps its tokens:**
```dart
// Bullseye — maps BsTokens into PkColorScheme
final bullseyeScheme = PkColorScheme.dark(
  primary: BsTokens.gold,
  onPrimary: BsTokens.black,
  surface: BsTokens.bgPrimary,
  onSurface: BsTokens.textPrimary,
  error: BsTokens.red,
);
final theme = bullseyeScheme.toThemeData(
  typography: PkTypography(fontFamily: 'Inter'),
);

// PawTrack — maps AppColors
final pawTrackScheme = PkColorScheme.light(
  primary: AppColors.primary,
  surface: AppColors.background,
  // ...
);
```

---

## PrimeKit Gaps — GoogleCalendarProvider (detail)

**`google_calendar_provider.dart`** — `CalendarProvider` impl using Google Calendar API v3

- Requires `googleapis: ^13.0.0` (added to `pubspec.yaml`)
- Injects `GoogleSignIn` → OAuth headers via `_AuthenticatedClient`
- Auto-retry on 401/403 via `signInSilently(reAuthenticate: true)`
- Bonus: `getCalendarList()` returns `List<({String id, String name})>` for picker UI

**How apps migrate:**
```dart
// Before (PawTrack lib/core/services/calendar_service.dart — delete this file)
// Before (best_todo_list — similar bespoke singleton — delete)

// After — one line in main.dart / auth init:
CalendarService.configure(
  GoogleCalendarProvider(googleSignIn: googleSignIn),
);

// Usage unchanged everywhere:
await CalendarService.instance.createEvent(event);
await CalendarService.instance.deleteEvent(id);
final ids = await CalendarService.instance.getCalendarIds();
```

---

## Audit Log Module — Detail

New module: `import 'package:primekit/audit.dart'`

### Files created

| File | Purpose |
|------|---------|
| `src/audit/audit_event.dart` | Immutable event record: type, userId, appId, resourceId/Type, payload, metadata, timestamp, auto-UUID |
| `src/audit/audit_query.dart` | Filter params: userId, appId, eventType, resourceId, resourceType, from/to, limit, order |
| `src/audit/audit_backend.dart` | Abstract interface: `write(event)`, `query(query)`, `watch(query)` |
| `src/audit/audit_log_service.dart` | Singleton service: `configure()`, `log()`, `logEvent()`, `query()`, `watch()`, `setEnabled()` |
| `src/audit/backends/firestore_audit_backend.dart` | Firestore impl — writes to configurable collection, supports all query filters + live `watch()` |
| `src/audit/backends/in_memory_audit_backend.dart` | In-memory impl for tests — inspectable `.events` list |
| `lib/audit.dart` | Public barrel export |

### How to wire it per app

**Bullseye — setup in main.dart:**
```dart
AuditLogService.instance.configure(
  FirestoreAuditBackend(
    firestore: FirebaseFirestore.instance,
    collectionPath: 'audit_logs',
  ),
  appId: 'bullseye',
);
```

**Bullseye — log events at call sites:**
```dart
// In MatchesNotifier.submitGuess()
AuditLogService.instance.logEvent(
  eventType: 'guess_submitted',
  userId: user.userId,
  resourceId: guess.matchId,
  resourceType: 'match',
  payload: {'home': guess.homeScore, 'away': guess.awayScore, 'tournamentId': tournamentId},
);

// In MatchesNotifier.deleteGuess()
AuditLogService.instance.logEvent(
  eventType: 'guess_deleted',
  userId: user.userId,
  resourceId: matchId,
  resourceType: 'match',
);
```

**Query in admin/debug screens:**
```dart
// All guesses by a user
final events = await AuditLogService.instance.query(
  AuditQuery(userId: user.id, eventType: 'guess_submitted', limit: 100),
);

// Everything that happened to a specific match
final events = await AuditLogService.instance.query(
  AuditQuery(resourceType: 'match', resourceId: matchId),
);

// Live stream for a group activity feed
AuditLogService.instance.watch(
  AuditQuery(appId: 'bullseye', limit: 20),
).listen((events) => setState(() => _feed = events));
```

### Apps × recommended events

| App | Event types to log |
|-----|--------------------|
| Bullseye | `guess_submitted`, `guess_deleted`, `group_joined`, `group_created`, `tournament_opened`, `member_kicked` |
| Splitly | `expense_created`, `expense_edited`, `expense_deleted`, `balance_settled`, `member_added`, `member_removed` |
| PawTrack | `vaccine_logged`, `vaccine_marked_done`, `medication_added`, `health_entry_added`, `pet_created`, `pdf_exported` |
| best_todo_list | `task_created`, `task_completed`, `task_deleted`, `ai_recommendation_applied`, `calendar_event_created` |

### Firestore indexes to create

```
Collection: audit_logs
Indexes:
  1. userId ASC + timestamp DESC
  2. appId ASC + eventType ASC + timestamp DESC
  3. resourceType ASC + resourceId ASC + timestamp DESC
```
