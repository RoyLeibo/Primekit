# PrimeKit Integration — Remaining Work

_Last updated: 2026-03-11_

---

## Done ✅

- **Phase 1 + 2 for all apps** — connectivity, storage, permissions, notifications, media upload, contacts, currency formatting, sync status, auth interceptors
- **PrimeKit v2.0.3 published** to pub.dev, all apps pointing to it
- **New PrimeKit modules built**: `currency.dart`, `contacts.dart`, `HivePendingChangeStore`, `PkSyncStatusBadge`
- **Splitly CI**: all 3 jobs green (Analyze & Test, Build Android, Build iOS)
- **pub.dev score**: 145/160 on v2.0.2, v2.0.3 should reach 160/160 once analyzed

---

## 🔴 Blocking

### Bullseye — Riverpod 2.x → 3.x Migration

App currently fails to compile. Affected files:

| File | Issue |
|------|-------|
| `lib/providers/auth_provider.dart` | `StateNotifier` / `StateNotifierProvider` removed |
| `lib/providers/groups_provider.dart` | Same |
| `lib/providers/matches_provider.dart` | Same + `mounted`, `dispose` pattern changes |
| `lib/screens/matches/matches_screen.dart` | `.valueOrNull` → `.value` |
| `lib/screens/home/home_screen.dart` | `.valueOrNull` → `.value` |
| `lib/widgets/scoring_info_sheet.dart` | `.valueOrNull` → `.value` |

**Migration rules:**
- `StateNotifier<T>` → `Notifier<T>` or `AsyncNotifier<T>`
- `StateNotifierProvider` → `NotifierProvider` or `AsyncNotifierProvider`
- `.valueOrNull` → `.value`
- `mounted` / `dispose` → no longer available on notifiers; use `ref.onDispose` instead

---

## 🟡 Quick Wins (~30 min)

### PawTrack — Delete 3 Wrapper Files (124 lines)

These files are pure pass-throughs over PrimeKit and should be deleted:

| File | Lines | Replace with |
|------|-------|-------------|
| `core/widgets/confirmation_dialog.dart` | 34 | `ConfirmDialog.show()` directly (~5 call sites) |
| `core/widgets/empty_state_widget.dart` | 42 | `EmptyState()` directly (~8 call sites) |
| `core/widgets/loading_shimmer.dart` | 48 | `SkeletonLoader` directly (~6 call sites) |

---

## 🟠 Phase 3 — Value-Add Features

| Feature | Apps | PrimeKit Module | Status |
|---------|------|----------------|--------|
| ~~Analytics + funnels~~ | All 4 | `analytics.dart` | ✅ Done (2026-03-11) |
| ~~RBAC (group admin/member roles)~~ | Splitly, Bullseye | `rbac.dart` | ✅ Done (2026-03-11) |
| ~~Forms validation~~ | PawTrack | `forms.dart` | ✅ Done (2026-03-11) |
| Billing + Membership | Bullseye, best_todo_list | `billing.dart`, `membership.dart` | ⏳ Deferred |
| Feature flags | All 4 | `flags.dart` | ⏳ Deferred |

---

## 🔵 PrimeKit Gaps — All Resolved ✅

All gaps built in PrimeKit 2.1.0 and 2.2.0:

| Gap | Built In | Notes |
|-----|---------|-------|
| Design System (`PkColorScheme` + `PkTypography`) | 2.1.0 | All 4 apps migrated |
| `FirebaseAuthInterceptor` | 2.1.0 | All apps wired |
| `GoogleCalendarProvider` | 2.1.0 | best_todo_list + PawTrack migrated |
| `RemoteNotificationPreferences` | 2.1.0 | Available — wirable when notification settings UI is added |
| `SyncStatusMonitor` | 2.1.0 | Splitly + PawTrack wired |
| `DebugAnalyticsProvider` | 2.2.0 | All 4 apps use it |

---

## Remaining Open Items

| Item | Priority | Notes |
|------|----------|-------|
| Upgrade all 4 apps to `primekit: ^2.2.0` (remove path overrides) | Low | Blocked on pub.dev indexing 2.2.0. TODO comment in each pubspec. |
| Billing + Membership wiring | Deferred | Pro tier (Bullseye), AI metering (best_todo_list) |
| Feature flags wiring | Deferred | Kill switches, A/B tests, gradual rollout |
