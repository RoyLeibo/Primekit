# design_system — Design Tokens & Shared Themes

**Purpose:** Shared design tokens (colors, typography, spacing, radii), theme system, and basic UI primitives.

**Key exports:**
- `PkAppTheme` — swappable theme definitions with light/dark support. Factories: `.pawTrack()`, `.freshMint()`, `.bullseyeGold()`, `.cosmicDark()`
- `PkAppThemeExtension` — generic ThemeExtension with surface tints, accents, glass surfaces, text colors, avatar palette
- `PkGradients` — branded gradient definitions (hero, positive, negative, accent, celebration)
- `PkColorScheme` — semantic colors (primary, surface, error, onPrimary, etc.)
- `PkTypography` — text styles (display, heading, body, label sizes)
- `PkSpacing` — margin/padding scale (xs, sm, md, lg, xl, 2xl)
- `PkRadius` — border radius tokens (sm, md, lg, full)
- `PkBadge` — badge widget
- `PkAvatar` — avatar widget with deterministic color assignment

**Theme system:** See `THEMES.md` in repo root for full theme documentation.

**Dependencies:** flutter, Material Design

**Maintenance:** Update when new theme added, token scale changed, or primitive widget added.
