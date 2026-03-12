# ui — General-Purpose UI Widgets

**Purpose:** Reusable Flutter widgets for common UI patterns.

**Key exports:**
- `AdaptiveScaffold` — responsive layout (mobile/tablet/desktop breakpoints)
- `PkUiTheme` — theme controller
- `SkeletonLoader` — shimmer loading placeholder
- `EmptyState` — empty content widget (icon + title + subtitle + action)
- `LazyList` — virtualized list with built-in pagination support
- `ToastService` — programmatic toast notifications
- `ConfirmDialog` — confirmation dialog with OK/Cancel
- `LoadingOverlay` — full-screen loading indicator
- `SyncStatusBadge` — shows sync state (from `sync` module)
- `InAppBannerService` — in-app notification banners
- `LegalLinksWidget` — privacy policy + terms of service links

**Active usage:** PawTrack uses `ConfirmDialog`, `EmptyState`, `SkeletonLoader`, `ToastService`, `InAppBannerService`.

**Dependencies:** flutter, `design_system`

**Maintenance:** Update when new widget added.
