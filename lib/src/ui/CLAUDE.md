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
- `PkGlassCard` — glassmorphism card with frosted blur + optional gradient border
- `PkConfettiOverlay` / `PkConfettiController` — confetti burst + rain animations
- `PkProgressBar` — animated progress bar (value, gradient, leading dot)
- `StatusBadge<T>` — generic multi-state status indicator (text/icon/dot)
- `PkNumericStepper` — +/- stepper with long-press rapid change
- `PkItemPickerSheet<T>` — searchable bottom sheet for single/multi-select
- `PkOnboardingFlow` — swipeable onboarding pages with progress dots
- `PkScreenshotShareService` — capture widget as image + native share

**Active usage:** PawTrack uses `ConfirmDialog`, `EmptyState`, `SkeletonLoader`, `ToastService`, `InAppBannerService`. best_todo_list uses `ToastService`, `EmptyState`, `ConfirmDialog`, `PkGlassCard`, `PkConfettiOverlay`, `PkProgressBar`. PawTrack wraps `StatusBadge`. Bullseye wraps `EmptyState`, `SkeletonLoader`, `ToastService`, `PkConfettiOverlay`.

**Dependencies:** flutter, `design_system`, `share_plus`

**Maintenance:** Update when new widget added.
