import 'package:flutter/material.dart';

/// A typography scale for PrimeKit-based apps.
///
/// Provide a [fontFamily] (or leave it null to fall back on the system font)
/// and call [toTextTheme] to get a Material 3–compatible [TextTheme] with a
/// consistent size / weight progression.
///
/// ```dart
/// final typography = PkTypography(fontFamily: 'Inter');
///
/// // Use with PkColorScheme:
/// final theme = PkColorScheme.light(...).toThemeData(typography: typography);
///
/// // Or build a TextTheme standalone:
/// final textTheme = typography.toTextTheme(colorScheme);
/// ```
///
/// ### Named styles
///
/// | Name | Size | Weight | Use case |
/// |------|------|--------|----------|
/// | [displayLg] | 57 | 400 | Hero headers |
/// | [displayMd] | 45 | 400 | Section banners |
/// | [displaySm] | 36 | 400 | Large labels |
/// | [headingLg] | 32 | 600 | Page titles |
/// | [headingMd] | 28 | 600 | Card headers |
/// | [headingSm] | 24 | 600 | Widget titles |
/// | [titleLg] | 22 | 500 | List headers |
/// | [titleMd] | 16 | 500 | Dialog titles |
/// | [titleSm] | 14 | 500 | Subtitle rows |
/// | [bodyLg] | 16 | 400 | Primary body |
/// | [bodyMd] | 14 | 400 | Default body |
/// | [bodySm] | 12 | 400 | Secondary body |
/// | [labelLg] | 14 | 500 | Buttons |
/// | [labelMd] | 12 | 500 | Chips, badges |
/// | [labelSm] | 11 | 500 | Captions |
class PkTypography {
  const PkTypography({
    this.fontFamily,
    this.displayFontFamily,
    this.letterSpacingScale = 1.0,
  });

  /// Font family for body and UI text (e.g. `'Inter'`).
  final String? fontFamily;

  /// Optional distinct font for display styles. Falls back to [fontFamily].
  final String? displayFontFamily;

  /// Multiplier applied to all letter-spacing values. Default `1.0` (no change).
  final double letterSpacingScale;

  // ---------------------------------------------------------------------------
  // Named text styles (context-free, no colour)
  // ---------------------------------------------------------------------------

  TextStyle get displayLg => _style(57, FontWeight.w400, -0.25, display: true);
  TextStyle get displayMd => _style(45, FontWeight.w400, 0, display: true);
  TextStyle get displaySm => _style(36, FontWeight.w400, 0, display: true);

  TextStyle get headingLg => _style(32, FontWeight.w600, 0);
  TextStyle get headingMd => _style(28, FontWeight.w600, 0);
  TextStyle get headingSm => _style(24, FontWeight.w600, 0);

  TextStyle get titleLg => _style(22, FontWeight.w500, 0);
  TextStyle get titleMd => _style(16, FontWeight.w500, 0.15);
  TextStyle get titleSm => _style(14, FontWeight.w500, 0.1);

  TextStyle get bodyLg => _style(16, FontWeight.w400, 0.5);
  TextStyle get bodyMd => _style(14, FontWeight.w400, 0.25);
  TextStyle get bodySm => _style(12, FontWeight.w400, 0.4);

  TextStyle get labelLg => _style(14, FontWeight.w500, 0.1);
  TextStyle get labelMd => _style(12, FontWeight.w500, 0.5);
  TextStyle get labelSm => _style(11, FontWeight.w500, 0.5);

  // ---------------------------------------------------------------------------
  // Flutter TextTheme conversion
  // ---------------------------------------------------------------------------

  /// Returns a Material 3 [TextTheme] populated with this typography scale.
  ///
  /// [colorScheme] is used to apply appropriate foreground colours:
  /// display/headline styles receive [ColorScheme.onSurface] and label styles
  /// receive [ColorScheme.onSurfaceVariant].
  TextTheme toTextTheme(ColorScheme colorScheme) {
    final primary = colorScheme.onSurface;
    final secondary = colorScheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: displayLg.copyWith(color: primary),
      displayMedium: displayMd.copyWith(color: primary),
      displaySmall: displaySm.copyWith(color: primary),
      headlineLarge: headingLg.copyWith(color: primary),
      headlineMedium: headingMd.copyWith(color: primary),
      headlineSmall: headingSm.copyWith(color: primary),
      titleLarge: titleLg.copyWith(color: primary),
      titleMedium: titleMd.copyWith(color: primary),
      titleSmall: titleSm.copyWith(color: primary),
      bodyLarge: bodyLg.copyWith(color: primary),
      bodyMedium: bodyMd.copyWith(color: primary),
      bodySmall: bodySm.copyWith(color: secondary),
      labelLarge: labelLg.copyWith(color: primary),
      labelMedium: labelMd.copyWith(color: secondary),
      labelSmall: labelSm.copyWith(color: secondary),
    );
  }

  // ---------------------------------------------------------------------------
  // Copy with
  // ---------------------------------------------------------------------------

  PkTypography copyWith({
    String? fontFamily,
    String? displayFontFamily,
    double? letterSpacingScale,
  }) => PkTypography(
    fontFamily: fontFamily ?? this.fontFamily,
    displayFontFamily: displayFontFamily ?? this.displayFontFamily,
    letterSpacingScale: letterSpacingScale ?? this.letterSpacingScale,
  );

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  TextStyle _style(
    double size,
    FontWeight weight,
    double letterSpacing, {
    bool display = false,
  }) => TextStyle(
    fontFamily: display ? (displayFontFamily ?? fontFamily) : fontFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing * letterSpacingScale,
    height: _lineHeight(size),
  );

  static double _lineHeight(double fontSize) {
    if (fontSize >= 45) return 1.12;
    if (fontSize >= 28) return 1.2;
    if (fontSize >= 20) return 1.3;
    return 1.5;
  }
}
