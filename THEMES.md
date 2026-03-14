# PrimeKit Shared Themes

Four swappable themes available via `PkAppTheme`. Any app can use any theme.

## Quick Start

```dart
import 'package:primekit/design_system.dart';
import 'package:primekit/riverpod.dart';

// Pick a theme
final theme = PkAppTheme.freshMint();

// Use in MaterialApp
MaterialApp(
  theme: theme.light()?.copyWith(/* app overrides */),
  darkTheme: theme.dark().copyWith(/* app overrides */),
  themeMode: ref.watch(pkThemeProvider).mode,
);

// Access extension tokens in widgets
final ext = PkAppThemeExtension.of(context);
final gradients = theme.gradients(context);
```

## Theme Registry

| ID | Name | Palette | Fonts | Light | Dark | Designed For |
|----|------|---------|-------|-------|------|-------------|
| `pawtrack` | PawTrack | Teal & Amber | Nunito | Yes | Yes | Health & lifestyle |
| `fresh_mint` | Fresh Mint | Emerald & Lime | Poppins + Inter | Yes | Yes | Social & finance |
| `bullseye` | Bullseye Gold | Black & Gold | System (SF Pro) | Yes | Yes | Sports & gaming |
| `cosmic_dark` | Cosmic Dark | Purple & Neon | Inter | Yes | Yes | Productivity & creative |

## PawTrack — Teal & Amber

Friendly, rounded design. Warm amber accents on a teal base.

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#0D9488` (teal600) | `#2DD4BF` (teal400) |
| Secondary | `#F59E0B` (amber500) | `#FBBF24` (amber400) |
| Surface | `#FFFFFF` | `#1E1E1E` |
| Background | `#FAFAFA` | `#171717` |
| Error | `#EF4444` | `#EF4444` |
| Success | `#22C55E` | `#22C55E` |

**Gradients:** Teal hero, green positive, red negative, amber accent, teal-amber celebration.

## Fresh Mint — Emerald & Lime

Fresh, vibrant design. Mint green with lime and cyan accents.

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#10B981` (emerald) | `#10B981` |
| Secondary | `#84CC16` (lime) | `#84CC16` |
| Surface | `#FFFFFF` | `#161B22` |
| Background | `#E8F5E9` | `#0D1117` |
| Error | `#EF4444` | `#F87171` |
| Success | `#10B981` | `#10B981` |

**Gradients:** Mint-to-lime hero, emerald positive, red negative, cyan accent, 3-color celebration.
**Extra:** Poppins for display/headings, Inter for body text.

## Bullseye Gold — Black & Gold

Bold, premium dark design. Gold on deep black.

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#D4850F` (gold dark) | `#F5A623` (gold) |
| Secondary | `#D4850F` | `#F5A623` |
| Surface | `#FFFFFF` | `#141414` |
| Background | `#F8F6F0` | `#0A0A0A` |
| Error | `#FF3B30` | `#FF3B30` |
| Success | `#1A8F3C` | `#30D158` |

**Gradients:** Gold hero, green positive, red negative, orange accent, tricolor celebration.
**Extra:** System fonts (SF Pro on iOS). Chart palette: orange, purple, amber.

## Cosmic Dark — Purple & Neon

Deep cosmic glassmorphism. Purple and neon accent palette.

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#7C6BC4` (deep purple) | `#9B85E8` (purple) |
| Secondary | `#3D8FD4` (blue) | `#5EB3F6` (blue) |
| Surface | `#FFFFFF` | `#111128` |
| Background | `#F5F3FF` | `#0A0A1A` |
| Error | `#C44040` | `#E05555` |
| Success | `#3AA080` | `#4CC5A0` |

**Gradients:** Purple-to-blue hero, teal-to-green positive, red negative, 3-color energy accent, 4-color celebration.
**Extra:** Inter font. Glass surfaces with 6% white bg / 10% white border.

## PkAppThemeExtension Tokens

Available on every theme via `PkAppThemeExtension.of(context)`:

| Token | Purpose |
|-------|---------|
| `surfaceTint` | Subtle tinted surface |
| `surfaceTintStrong` | Stronger tinted surface |
| `glassBg` | Frosted glass background |
| `glassBorder` | Glass border stroke |
| `primaryDark` | Darker primary variant |
| `primaryLight` | Lighter primary variant |
| `successDark` | Darker success variant |
| `errorDark` | Darker error variant |
| `divider` | Divider color |
| `accent1`–`accent6` | 6-slot accent palette |
| `textPrimary` | High-emphasis text |
| `textSecondary` | Medium-emphasis text |
| `textTertiary` | Low-emphasis text |
| `avatarColors` | 6-color avatar palette |

## Adding a New Theme

1. Create `Primekit/lib/src/design_system/themes/my_theme.dart`
2. Implement `PkAppTheme buildMyTheme()` returning a `PkAppTheme`
3. Add import + factory in `pk_app_theme.dart`
4. Add to the `all` list
5. Update this file
