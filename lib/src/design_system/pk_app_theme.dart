import 'package:flutter/material.dart';

import 'pk_app_theme_extension.dart';
import 'pk_color_scheme.dart';
import 'pk_gradients.dart';
import 'pk_typography.dart';
import '../ui/pk_ui_theme.dart';
import 'themes/pawtrack_theme.dart' as pawtrack;
import 'themes/fresh_mint_theme.dart' as fresh_mint;
import 'themes/bullseye_theme.dart' as bullseye;
import 'themes/cosmic_dark_theme.dart' as cosmic_dark;

/// A complete, swappable theme definition for PrimeKit-based apps.
///
/// Each theme bundles color schemes (light + dark), typography, extensions,
/// gradients, and UI theme overrides. Apps use the theme as a base and
/// optionally apply component-specific overrides on top.
///
/// ```dart
/// final theme = PkAppTheme.freshMint();
///
/// MaterialApp(
///   theme: theme.light(),
///   darkTheme: theme.dark(),
///   themeMode: themeMode,
/// );
/// ```
///
/// To add a new theme:
/// 1. Create a file in `themes/` with a builder function
/// 2. Add a static factory here
/// 3. Add to [all] list
@immutable
class PkAppTheme {
  const PkAppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.darkScheme,
    required this.darkTypography,
    required this.darkUiTheme,
    required this.darkExtension,
    required this.darkGradients,
    this.lightScheme,
    this.lightTypography,
    this.lightUiTheme,
    this.lightExtension,
    this.lightGradients,
  });

  /// Unique identifier (e.g. `'pawtrack'`, `'fresh_mint'`).
  final String id;

  /// Human-readable name (e.g. `'PawTrack'`, `'Fresh Mint'`).
  final String name;

  /// Short description of the theme's visual character.
  final String description;

  // ── Dark mode (always required) ─────────────────────────────────
  final PkColorScheme darkScheme;
  final PkTypography darkTypography;
  final PkUiTheme darkUiTheme;
  final PkAppThemeExtension darkExtension;
  final PkGradients darkGradients;

  // ── Light mode (optional — null for dark-only themes) ───────────
  final PkColorScheme? lightScheme;
  final PkTypography? lightTypography;
  final PkUiTheme? lightUiTheme;
  final PkAppThemeExtension? lightExtension;
  final PkGradients? lightGradients;

  /// Whether this theme supports light mode.
  bool get supportsLightMode => lightScheme != null;

  // ── Theme builders ──────────────────────────────────────────────

  /// Builds a [ThemeData] for light mode.
  ///
  /// Returns null if this theme doesn't support light mode.
  /// Apps can extend via `theme.light()!.copyWith(...)`.
  ThemeData? light() {
    final scheme = lightScheme;
    if (scheme == null) return null;

    final typography = lightTypography ?? darkTypography;
    final colorScheme = scheme.toColorScheme();
    final textTheme = typography.toTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      cardColor: scheme.surfaceVariant,
      dividerColor: scheme.outline,
      shadowColor: scheme.shadow,
      extensions: [
        lightUiTheme ?? const PkUiTheme(),
        lightExtension!,
      ],
    );
  }

  /// Builds a [ThemeData] for dark mode.
  ///
  /// Apps can extend via `theme.dark().copyWith(...)`.
  ThemeData dark() {
    final colorScheme = darkScheme.toColorScheme();
    final textTheme = darkTypography.toTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: darkScheme.surface,
      cardColor: darkScheme.surfaceVariant,
      dividerColor: darkScheme.outline,
      shadowColor: darkScheme.shadow,
      extensions: [
        darkUiTheme,
        darkExtension,
      ],
    );
  }

  /// Returns the appropriate [PkGradients] for the given brightness.
  PkGradients gradients(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkGradients : (lightGradients ?? darkGradients);
  }

  /// Returns the appropriate [PkAppThemeExtension] for the given brightness.
  PkAppThemeExtension extension(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkExtension : (lightExtension ?? darkExtension);
  }

  // ── Registry ────────────────────────────────────────────────────

  /// All built-in themes.
  static List<PkAppTheme> get all => [
        PkAppTheme.pawTrack(),
        PkAppTheme.freshMint(),
        PkAppTheme.bullseyeGold(),
        PkAppTheme.cosmicDark(),
      ];

  /// Look up a theme by [id]. Throws if not found.
  static PkAppTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: PkAppTheme.pawTrack);

  // ── Theme factories ─────────────────────────────────────────────

  /// Teal & Amber — friendly, rounded. Designed for PawTrack (pet health).
  /// Supports light + dark.
  factory PkAppTheme.pawTrack() => pawtrack.buildPawTrackTheme();

  /// Emerald & Lime — fresh, vibrant. Designed for Splitly (expense splitting).
  /// Supports light + dark.
  factory PkAppTheme.freshMint() => fresh_mint.buildFreshMintTheme();

  /// Black & Gold — bold, premium. Designed for Bullseye (football predictions).
  /// Supports light + dark.
  factory PkAppTheme.bullseyeGold() => bullseye.buildBullseyeTheme();

  /// Deep purple & neon — cosmic glassmorphism. Designed for best_todo_list.
  /// Supports light + dark.
  factory PkAppTheme.cosmicDark() => cosmic_dark.buildCosmicDarkTheme();
}
