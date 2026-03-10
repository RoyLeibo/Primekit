import 'package:flutter/material.dart';

/// A semantic color token set that maps to Flutter's Material 3 [ColorScheme].
///
/// Define your brand colors once in `PkColorScheme` and call [toThemeData] to
/// get a fully configured `ThemeData`. This ensures PrimeKit UI components
/// (which read from `Theme.of(context).colorScheme`) automatically adopt your
/// app's palette.
///
/// ```dart
/// // Define in theme.dart
/// final lightScheme = PkColorScheme.light(
///   primary: Color(0xFFD4A017),       // gold
///   onPrimary: Color(0xFF000000),
///   surface: Color(0xFF121212),
///   onSurface: Color(0xFFFFFFFF),
///   error: Color(0xFFCF6679),
/// );
///
/// // Use in MaterialApp
/// MaterialApp(
///   theme: lightScheme.toThemeData(typography: PkTypography(fontFamily: 'Inter')),
/// );
/// ```
class PkColorScheme {
  const PkColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.error,
    required this.onError,
    required this.outline,
    required this.shadow,
    this.brightness = Brightness.light,
  });

  // ---------------------------------------------------------------------------
  // Semantic tokens
  // ---------------------------------------------------------------------------

  /// Brand primary colour — used for buttons, active states, highlights.
  final Color primary;

  /// Text/icon colour on top of [primary].
  final Color onPrimary;

  /// Secondary accent — used for chips, badges, secondary actions.
  final Color secondary;

  /// Text/icon colour on top of [secondary].
  final Color onSecondary;

  /// Default background / card colour.
  final Color surface;

  /// Default text / icon colour on [surface].
  final Color onSurface;

  /// Slightly elevated surface — drawers, sheets, hover states.
  final Color surfaceVariant;

  /// Muted text / icon colour on [surfaceVariant].
  final Color onSurfaceVariant;

  /// Destructive / error colour.
  final Color error;

  /// Text/icon colour on top of [error].
  final Color onError;

  /// Border / divider colour.
  final Color outline;

  /// Drop shadow colour.
  final Color shadow;

  /// Whether this scheme targets a light or dark host theme.
  final Brightness brightness;

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// A neutral light scheme — good as a starting point for customisation.
  factory PkColorScheme.light({
    Color primary = const Color(0xFF6750A4),
    Color onPrimary = Colors.white,
    Color secondary = const Color(0xFF625B71),
    Color onSecondary = Colors.white,
    Color surface = const Color(0xFFFFFBFE),
    Color onSurface = const Color(0xFF1C1B1F),
    Color surfaceVariant = const Color(0xFFE7E0EC),
    Color onSurfaceVariant = const Color(0xFF49454F),
    Color error = const Color(0xFFB3261E),
    Color onError = Colors.white,
    Color outline = const Color(0xFF79747E),
    Color shadow = Colors.black,
  }) => PkColorScheme(
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    error: error,
    onError: onError,
    outline: outline,
    shadow: shadow,
    brightness: Brightness.light,
  );

  /// A neutral dark scheme — good as a starting point for customisation.
  factory PkColorScheme.dark({
    Color primary = const Color(0xFFD0BCFF),
    Color onPrimary = const Color(0xFF381E72),
    Color secondary = const Color(0xFFCCC2DC),
    Color onSecondary = const Color(0xFF332D41),
    Color surface = const Color(0xFF1C1B1F),
    Color onSurface = const Color(0xFFE6E1E5),
    Color surfaceVariant = const Color(0xFF49454F),
    Color onSurfaceVariant = const Color(0xFFCAC4D0),
    Color error = const Color(0xFFF2B8B5),
    Color onError = const Color(0xFF601410),
    Color outline = const Color(0xFF938F99),
    Color shadow = Colors.black,
  }) => PkColorScheme(
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    error: error,
    onError: onError,
    outline: outline,
    shadow: shadow,
    brightness: Brightness.dark,
  );

  // ---------------------------------------------------------------------------
  // Conversion
  // ---------------------------------------------------------------------------

  /// Converts to Flutter's [ColorScheme].
  ColorScheme toColorScheme() => ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primary.withValues(alpha: 0.12),
    onPrimaryContainer: primary,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondary.withValues(alpha: 0.12),
    onSecondaryContainer: secondary,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    error: error,
    onError: onError,
    errorContainer: error.withValues(alpha: 0.12),
    onErrorContainer: error,
    outline: outline,
    shadow: shadow,
    scrim: shadow.withValues(alpha: 0.32),
    inverseSurface: onSurface,
    onInverseSurface: surface,
    inversePrimary: primary.withValues(alpha: 0.7),
  );

  /// Builds a complete [ThemeData] from this scheme.
  ///
  /// Pass a [PkTypography] to apply a custom font; otherwise Flutter's
  /// default typography is used.
  ThemeData toThemeData({PkTypography? typography}) {
    final colorScheme = toColorScheme();
    final textTheme = typography?.toTextTheme(colorScheme) ??
        ThemeData(colorScheme: colorScheme).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: surface,
      cardColor: surfaceVariant,
      dividerColor: outline,
      shadowColor: shadow,
    );
  }

  // ---------------------------------------------------------------------------
  // Copy with
  // ---------------------------------------------------------------------------

  PkColorScheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? error,
    Color? onError,
    Color? outline,
    Color? shadow,
    Brightness? brightness,
  }) => PkColorScheme(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary ?? this.secondary,
    onSecondary: onSecondary ?? this.onSecondary,
    surface: surface ?? this.surface,
    onSurface: onSurface ?? this.onSurface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    outline: outline ?? this.outline,
    shadow: shadow ?? this.shadow,
    brightness: brightness ?? this.brightness,
  );
}
