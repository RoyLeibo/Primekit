import 'package:flutter/material.dart';

import '../pk_app_theme.dart';
import '../pk_app_theme_extension.dart';
import '../pk_color_scheme.dart';
import '../pk_gradients.dart';
import '../pk_typography.dart';
import '../../ui/pk_ui_theme.dart';

PkAppTheme buildCosmicDarkTheme() {
  // ── Accent palette ────────────────────────────────────────────
  const purple = Color(0xFF9B85E8);
  const blue = Color(0xFF5EB3F6);
  const teal = Color(0xFF3ABFCC);
  const green = Color(0xFF4CC5A0);
  const amber = Color(0xFFE8B544);
  const red = Color(0xFFE05555);

  // ── Dark surfaces ─────────────────────────────────────────────
  const bgSecondaryDark = Color(0xFF111128);
  const glassBgDark = Color(0x0FFFFFFF);
  const glassBorderDark = Color(0x1AFFFFFF);

  // ── Dark text ─────────────────────────────────────────────────
  const textPrimaryDark = Color(0xF2FFFFFF);
  const textSecondaryDark = Color(0x99FFFFFF);
  const textTertiaryDark = Color(0x66FFFFFF);

  // ── Light surfaces ────────────────────────────────────────────
  const surfaceLight = Color(0xFFFFFFFF);
  const surfaceTintLight = Color(0xFFEDE9FE);
  const surfaceTintStrongLight = Color(0xFFDDD6FE);
  const dividerLight = Color(0xFFE2E0F0);

  // ── Light text ────────────────────────────────────────────────
  const textPrimaryLight = Color(0xFF1A1035);
  const textSecondaryLight = Color(0xFF6B6490);
  const textTertiaryLight = Color(0xFF9E97BD);

  // ── Light accents (slightly deeper for contrast) ──────────────
  const purpleLight = Color(0xFF7C6BC4);
  const blueLight = Color(0xFF3D8FD4);
  const tealLight = Color(0xFF2A9FAA);
  const greenLight = Color(0xFF3AA080);
  const amberLight = Color(0xFFCC9A2E);
  const redLight = Color(0xFFC44040);

  const white = Color(0xFFFFFFFF);

  // ── Typography ────────────────────────────────────────────────
  const typography = PkTypography(fontFamily: 'Inter');

  // ── Dark scheme ───────────────────────────────────────────────
  const darkScheme = PkColorScheme(
    primary: purple,
    onPrimary: white,
    secondary: blue,
    onSecondary: white,
    surface: bgSecondaryDark,
    onSurface: textPrimaryDark,
    surfaceVariant: Color(0xFF1A1A2E),
    onSurfaceVariant: textSecondaryDark,
    error: red,
    onError: white,
    outline: glassBorderDark,
    shadow: Color(0xFF000000),
    brightness: Brightness.dark,
  );

  // ── Light scheme ──────────────────────────────────────────────
  const lightScheme = PkColorScheme(
    primary: purpleLight,
    onPrimary: white,
    secondary: blueLight,
    onSecondary: white,
    surface: surfaceLight,
    onSurface: textPrimaryLight,
    surfaceVariant: surfaceTintLight,
    onSurfaceVariant: textSecondaryLight,
    error: redLight,
    onError: white,
    outline: dividerLight,
    shadow: Color(0x1A7C6BC4),
    brightness: Brightness.light,
  );

  // ── Dark extension ────────────────────────────────────────────
  const darkExt = PkAppThemeExtension(
    surfaceTint: bgSecondaryDark,
    surfaceTintStrong: Color(0xFF1A1A2E),
    glassBg: glassBgDark,
    glassBorder: glassBorderDark,
    primaryDark: Color(0xFF7B6BC8),
    primaryLight: Color(0xFFB8A8F8),
    successDark: Color(0xFF3AA080),
    errorDark: Color(0xFFC44040),
    divider: glassBorderDark,
    accent1: purple,
    accent2: blue,
    accent3: teal,
    accent4: green,
    accent5: amber,
    accent6: red,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    textTertiary: textTertiaryDark,
    avatarColors: [purple, blue, teal, green, amber, red],
  );

  // ── Light extension ───────────────────────────────────────────
  const lightExt = PkAppThemeExtension(
    surfaceTint: surfaceTintLight,
    surfaceTintStrong: surfaceTintStrongLight,
    glassBg: Color(0x0F7C6BC4),
    glassBorder: Color(0x1A7C6BC4),
    primaryDark: Color(0xFF5B4BA4),
    primaryLight: purple,
    successDark: Color(0xFF2A8060),
    errorDark: Color(0xFFA43030),
    divider: dividerLight,
    accent1: purpleLight,
    accent2: blueLight,
    accent3: tealLight,
    accent4: greenLight,
    accent5: amberLight,
    accent6: redLight,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    textTertiary: textTertiaryLight,
    avatarColors: [purpleLight, blueLight, tealLight, greenLight, amberLight, redLight],
  );

  // ── Gradients ─────────────────────────────────────────────────
  const darkGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [purple, blue],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [teal, green],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [red, Color(0xFFC44040)],
    ),
    accent: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [purple, blue, teal],
    ),
    celebration: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [purple, blue, teal, green],
    ),
  );

  const lightGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [purpleLight, blueLight],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tealLight, greenLight],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [redLight, Color(0xFFA43030)],
    ),
    accent: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [purpleLight, blueLight, tealLight],
    ),
    celebration: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [purpleLight, blueLight, tealLight, greenLight],
    ),
  );

  // ── UI themes ─────────────────────────────────────────────────
  const darkUi = PkUiTheme(
    skeletonBaseColor: Color(0xFF1A1A2E),
    skeletonHighlightColor: bgSecondaryDark,
    successColor: green,
    errorColor: red,
  );

  const lightUi = PkUiTheme(
    skeletonBaseColor: Color(0xFFE8E5F5),
    skeletonHighlightColor: Color(0xFFF5F3FF),
    successColor: greenLight,
    errorColor: redLight,
  );

  return const PkAppTheme(
    id: 'cosmic_dark',
    name: 'Cosmic Dark',
    description: 'Deep purple & neon — cosmic glassmorphism. Ideal for productivity & creative apps.',
    lightScheme: lightScheme,
    lightTypography: typography,
    lightUiTheme: lightUi,
    lightExtension: lightExt,
    lightGradients: lightGradients,
    darkScheme: darkScheme,
    darkTypography: typography,
    darkUiTheme: darkUi,
    darkExtension: darkExt,
    darkGradients: darkGradients,
  );
}
