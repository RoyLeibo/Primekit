# analytics — Event Tracking

**Purpose:** Analytics provider abstraction. Swap Firebase/Segment/etc without changing call sites.

**Key exports:**
- `EventTracker` — main API; call `.track(eventName, properties)`
- `AnalyticsProvider` — abstract backend interface
- `FunnelTracker` — multi-step flow tracking (step entered/completed/abandoned)
- `SessionTracker` — session lifecycle tracking
- `EventCounter` — event frequency tracking
- `DebugAnalyticsProvider` — console-only provider for development

**Firebase provider:** `FirebaseAnalyticsProvider` (in `firebase.dart`)

**Dependencies:** `core`

**Pattern:** Wire `FirebaseAnalyticsProvider` in production, `DebugAnalyticsProvider` in dev.

**Maintenance:** Update when new tracking API added.
