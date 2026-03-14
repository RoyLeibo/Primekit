import 'package:flutter/material.dart';

/// Generic theme extension providing design tokens beyond Material's [ColorScheme].
///
/// Every [PkAppTheme] includes light and dark variants of this extension.
/// Access in widgets via `PkAppThemeExtension.of(context)`.
///
/// ```dart
/// final ext = PkAppThemeExtension.of(context);
/// Container(color: ext.surfaceTint);
/// ```
@immutable
class PkAppThemeExtension extends ThemeExtension<PkAppThemeExtension> {
  const PkAppThemeExtension({
    required this.surfaceTint,
    required this.surfaceTintStrong,
    required this.glassBg,
    required this.glassBorder,
    required this.primaryDark,
    required this.primaryLight,
    required this.successDark,
    required this.errorDark,
    required this.divider,
    required this.accent1,
    required this.accent2,
    required this.accent3,
    required this.accent4,
    required this.accent5,
    required this.accent6,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.avatarColors,
  });

  // ── Surface tints ───────────────────────────────────────────────
  /// Subtle tinted surface (e.g. selected card, hover bg).
  final Color surfaceTint;

  /// Stronger tinted surface (e.g. chip selected bg).
  final Color surfaceTintStrong;

  // ── Glass surfaces (for glassmorphism themes) ───────────────────
  /// Frosted glass background (typically 5–6% white).
  final Color glassBg;

  /// Glass border stroke (typically 10% white).
  final Color glassBorder;

  // ── Extended primary shades ─────────────────────────────────────
  /// Darker variant of the primary color.
  final Color primaryDark;

  /// Lighter variant of the primary color.
  final Color primaryLight;

  // ── Extended status ─────────────────────────────────────────────
  /// Darker success color (for gradients / pressed states).
  final Color successDark;

  /// Darker error color (for gradients / pressed states).
  final Color errorDark;

  // ── Divider ─────────────────────────────────────────────────────
  /// Divider/separator color (may differ from Material outline).
  final Color divider;

  // ── Accent palette (6 slots) ────────────────────────────────────
  /// Primary accent (brand highlight).
  final Color accent1;

  /// Secondary accent.
  final Color accent2;

  /// Tertiary accent.
  final Color accent3;

  /// Extra accent 4.
  final Color accent4;

  /// Extra accent 5 (often warning-toned).
  final Color accent5;

  /// Extra accent 6 (often error-toned).
  final Color accent6;

  // ── Text ────────────────────────────────────────────────────────
  /// High-emphasis text.
  final Color textPrimary;

  /// Medium-emphasis text.
  final Color textSecondary;

  /// Low-emphasis / disabled text.
  final Color textTertiary;

  // ── Avatar colors ───────────────────────────────────────────────
  /// Ordered list of avatar background colors.
  /// Use `avatarColors[index % avatarColors.length]`.
  final List<Color> avatarColors;

  // ── Convenience ─────────────────────────────────────────────────

  /// Shortcut to access from any widget context.
  static PkAppThemeExtension of(BuildContext context) =>
      Theme.of(context).extension<PkAppThemeExtension>()!;

  /// Safe version that returns null if not found.
  static PkAppThemeExtension? maybeOf(BuildContext context) =>
      Theme.of(context).extension<PkAppThemeExtension>();

  // ── ThemeExtension overrides ────────────────────────────────────

  @override
  PkAppThemeExtension copyWith({
    Color? surfaceTint,
    Color? surfaceTintStrong,
    Color? glassBg,
    Color? glassBorder,
    Color? primaryDark,
    Color? primaryLight,
    Color? successDark,
    Color? errorDark,
    Color? divider,
    Color? accent1,
    Color? accent2,
    Color? accent3,
    Color? accent4,
    Color? accent5,
    Color? accent6,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    List<Color>? avatarColors,
  }) {
    return PkAppThemeExtension(
      surfaceTint: surfaceTint ?? this.surfaceTint,
      surfaceTintStrong: surfaceTintStrong ?? this.surfaceTintStrong,
      glassBg: glassBg ?? this.glassBg,
      glassBorder: glassBorder ?? this.glassBorder,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      successDark: successDark ?? this.successDark,
      errorDark: errorDark ?? this.errorDark,
      divider: divider ?? this.divider,
      accent1: accent1 ?? this.accent1,
      accent2: accent2 ?? this.accent2,
      accent3: accent3 ?? this.accent3,
      accent4: accent4 ?? this.accent4,
      accent5: accent5 ?? this.accent5,
      accent6: accent6 ?? this.accent6,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      avatarColors: avatarColors ?? this.avatarColors,
    );
  }

  @override
  PkAppThemeExtension lerp(covariant PkAppThemeExtension? other, double t) {
    if (other == null) return this;
    return PkAppThemeExtension(
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      surfaceTintStrong:
          Color.lerp(surfaceTintStrong, other.surfaceTintStrong, t)!,
      glassBg: Color.lerp(glassBg, other.glassBg, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      successDark: Color.lerp(successDark, other.successDark, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent1: Color.lerp(accent1, other.accent1, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      accent3: Color.lerp(accent3, other.accent3, t)!,
      accent4: Color.lerp(accent4, other.accent4, t)!,
      accent5: Color.lerp(accent5, other.accent5, t)!,
      accent6: Color.lerp(accent6, other.accent6, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      avatarColors: _lerpColorList(avatarColors, other.avatarColors, t),
    );
  }

  static List<Color> _lerpColorList(
    List<Color> a,
    List<Color> b,
    double t,
  ) {
    final length = a.length > b.length ? a.length : b.length;
    return List.generate(length, (i) {
      final ca = i < a.length ? a[i] : b[i];
      final cb = i < b.length ? b[i] : a[i];
      return Color.lerp(ca, cb, t)!;
    });
  }
}
