# PrimeKit Integration — Remaining Work

_Last updated: 2026-03-11_

---

## Done ✅

Everything below is complete and pushed to all repos.

- **Phase 1 + 2** — connectivity, storage, permissions, notifications, media upload, contacts, currency formatting, sync status, auth interceptors (all apps)
- **Phase 3 — Analytics** — `EventTracker` + `DebugAnalyticsProvider` wired in all 4 apps; key events instrumented
- **Phase 3 — RBAC** — `RbacPolicy` + `RbacProvider` + `RbacGate` wired in Splitly and Bullseye (group admin/member roles)
- **Phase 3 — Forms** — 5 PawTrack form screens migrated to `PkSchema` validators
- **Phase 3 — AuditLogService** — configured + event call sites added in all 4 apps
- **Bullseye Riverpod 3.x migration** — complete
- **PrimeKit modules built**: `currency.dart`, `contacts.dart`, `audit.dart`, `calendar.dart` (`GoogleCalendarProvider`), `design_system.dart` (`PkColorScheme`, `PkTypography`), `auth.dart` (`FirebaseAuthInterceptor`), `network.dart` (`SyncStatusMonitor`), `notifications.dart` (`RemoteNotificationPreferences`), `analytics.dart` (`DebugAnalyticsProvider`)
- **PrimeKit 2.2.0 published** — `DebugAnalyticsProvider` added
- **pub.dev score**: 160/160

---

## 🟠 Remaining — Last 2 Integration Items

These are the only PrimeKit modules the apps haven't integrated yet.

### 1. Billing + Membership

| App | What to Wire | Module |
|-----|-------------|--------|
| **Bullseye** | Pro tier gating — lock premium features (advanced stats, custom scoring) behind `TierGate(requires: MembershipTier.pro)`. Wire `SubscriptionManager` + `PaywallController`. | `primekit/billing.dart`, `primekit/membership.dart` |
| **best_todo_list** | AI usage metering — gate AI input behind a usage quota. Wire `EntitlementChecker.canAccess('ai_parse')` + `PaywallController` when quota exceeded. | `primekit/billing.dart`, `primekit/membership.dart` |

**How to wire (both apps):**
```dart
// main.dart — configure once
MembershipService.instance.configure(/* tier resolver */);

// Gate a feature
TierGate(
  requires: MembershipTier.pro,
  fallback: UpgradePrompt(targetTier: MembershipTier.pro),
  child: const PremiumFeatureWidget(),
)

// Programmatic check
if (MembershipService.instance.currentTier.isAtLeast(MembershipTier.pro)) {
  // allow
}
```

---

### 2. Feature Flags

| App | What to Wire | Module |
|-----|-------------|--------|
| **All 4** | Kill switches, gradual rollout, A/B tests — wrap experimental features with `FlagService.instance.getBool('flag_name')`. Configure with `FirebaseFlagProvider` (Remote Config). | `primekit/flags.dart` |

**How to wire:**
```dart
// main.dart — configure once
FlagService.instance.configure(
  provider: FirebaseFlagProvider(),
  cache: FlagCache(ttl: const Duration(minutes: 5)),
);

// Usage anywhere
final enabled = await FlagService.instance.getBool('new_checkout_flow', defaultValue: false);
if (enabled) { /* show new flow */ }
```

**Recommended flags per app:**

| App | Flags |
|-----|-------|
| Bullseye | `new_scoring_ui`, `side_bets_enabled`, `season_predictions_v2` |
| Splitly | `recurring_expenses_enabled`, `ai_categorisation`, `group_chat_v2` |
| PawTrack | `vet_telehealth_enabled`, `pdf_export_v2`, `health_insights_ai` |
| best_todo_list | `ai_day_summary`, `kanban_view`, `habit_tracking_v2` |

---

## 🔧 Cleanup Item (not an integration)

**Upgrade all 4 apps from `^2.1.0` → `^2.2.0`** once pub.dev finishes indexing 2.2.0:

1. Remove `dependency_overrides: primekit: path: ../Primekit` from each `pubspec.yaml`
2. Update `primekit: ^2.1.0` → `primekit: ^2.2.0`
3. Run `flutter pub get` in each app
4. Commit + push all 4

Each `pubspec.yaml` already has a `# TODO: remove once primekit ^2.2.0 is indexed` comment marking the override.
