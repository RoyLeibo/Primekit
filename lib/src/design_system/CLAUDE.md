# design_system — Design Tokens

**Purpose:** Shared design tokens (colors, typography, spacing, radii) and basic UI primitives.

**Key exports:**
- `PkColorScheme` — semantic colors (primary, surface, error, onPrimary, etc.)
- `PkTypography` — text styles (display, heading, body, label sizes)
- `PkSpacing` — margin/padding scale (xs, sm, md, lg, xl, 2xl)
- `PkRadius` — border radius tokens (sm, md, lg, full)
- `PkBadge` — badge widget
- `PkAvatar` — avatar widget with deterministic color assignment

**Note:** Apps with custom design systems (e.g. Bullseye uses `BsTokens`/`BsSemantics`) may not use this directly — they implement their own tokens on top of Material.

**Dependencies:** flutter, Material Design

**Maintenance:** Update when new token scale added or primitive widget added.
