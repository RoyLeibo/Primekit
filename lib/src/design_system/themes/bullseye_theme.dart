import 'package:flutter/material.dart';

import '../pk_app_theme.dart';
import '../pk_app_theme_extension.dart';
import '../pk_color_scheme.dart';
import '../pk_gradients.dart';
import '../pk_typography.dart';
import '../../ui/pk_ui_theme.dart';

PkAppTheme buildBullseyeTheme() {
  // ── Brand ─────────────────────────────────────────────────────
  const gold = Color(0xFFF5A623);
  const goldDark = Color(0xFFD4850F);
  const goldFill = Color(0x1FF5A623);
  const goldBorder = Color(0x59F5A623);

  // ── Semantic status ───────────────────────────────────────────
  const red = Color(0xFFFF3B30);
  const redDark = Color(0xFFCC2F25);
  const green = Color(0xFF30D158);
  const greenDark = Color(0xFF25A84A);
  const blue = Color(0xFF0A84FF);

  // ── Dark surfaces ─────────────────────────────────────────────
  const card = Color(0xFF141414);
  const elevated = Color(0xFF1C1C1E);

  // ── Dark text ─────────────────────────────────────────────────
  const textPrimary = Color(0xFFFFFFFF);
  const textSecondary = Color(0xBFFFFFFF);
  const textTertiary = Color(0x61FFFFFF);

  // ── Dark borders ──────────────────────────────────────────────
  const border = Color(0x1AFFFFFF);

  // ── Chart palette ─────────────────────────────────────────────
  const chartOrange = Color(0xFFFF6B35);
  const chartPurple = Color(0xFF7B1FA2);
  const chartAmber = Color(0xFFFFA726);

  // ── Light surfaces ────────────────────────────────────────────
  const lightSurface = Color(0xFFFFFFFF);
  const lightSurfaceTint = Color(0xFFFFF8E1);
  const lightSurfaceTintStrong = Color(0xFFFFECB3);
  const lightDivider = Color(0xFFE0D6C2);

  // ── Light text ────────────────────────────────────────────────
  const lightTextPrimary = Color(0xFF1A1A1A);
  const lightTextSecondary = Color(0xFF6B6355);
  const lightTextTertiary = Color(0xFF9E9585);

  const white = Color(0xFFFFFFFF);

  // ── Typography (system font) ──────────────────────────────────
  const typography = PkTypography(letterSpacingScale: 1.0);

  // ── Dark scheme ───────────────────────────────────────────────
  const darkScheme = PkColorScheme(
    primary: gold,
    onPrimary: Color(0xFF000000),
    secondary: gold,
    onSecondary: Color(0xFF000000),
    surface: card,
    onSurface: textPrimary,
    surfaceVariant: elevated,
    onSurfaceVariant: textSecondary,
    error: red,
    onError: white,
    outline: border,
    shadow: Color(0xFF000000),
    brightness: Brightness.dark,
  );

  // ── Light scheme ──────────────────────────────────────────────
  const lightScheme = PkColorScheme(
    primary: goldDark,
    onPrimary: white,
    secondary: goldDark,
    onSecondary: white,
    surface: lightSurface,
    onSurface: lightTextPrimary,
    surfaceVariant: lightSurfaceTint,
    onSurfaceVariant: lightTextSecondary,
    error: red,
    onError: white,
    outline: lightDivider,
    shadow: Color(0x1A000000),
    brightness: Brightness.light,
  );

  // ── Dark extension ────────────────────────────────────────────
  const darkExt = PkAppThemeExtension(
    surfaceTint: goldFill,
    surfaceTintStrong: goldBorder,
    glassBg: Color(0x0DFFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    primaryDark: goldDark,
    primaryLight: gold,
    successDark: greenDark,
    errorDark: redDark,
    divider: border,
    accent1: gold,
    accent2: green,
    accent3: blue,
    accent4: chartOrange,
    accent5: chartAmber,
    accent6: red,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    avatarColors: [gold, green, blue, chartOrange, chartPurple, red],
  );

  // ── Light extension ───────────────────────────────────────────
  const lightExt = PkAppThemeExtension(
    surfaceTint: lightSurfaceTint,
    surfaceTintStrong: lightSurfaceTintStrong,
    glassBg: Color(0x0FF5A623),
    glassBorder: Color(0x1AF5A623),
    primaryDark: Color(0xFFB8760A),
    primaryLight: gold,
    successDark: greenDark,
    errorDark: redDark,
    divider: lightDivider,
    accent1: goldDark,
    accent2: Color(0xFF1A8F3C),
    accent3: Color(0xFF0066CC),
    accent4: Color(0xFFE85D2A),
    accent5: Color(0xFFD4940D),
    accent6: Color(0xFFD93025),
    textPrimary: lightTextPrimary,
    textSecondary: lightTextSecondary,
    textTertiary: lightTextTertiary,
    avatarColors: [goldDark, Color(0xFF1A8F3C), Color(0xFF0066CC), Color(0xFFE85D2A), Color(0xFF6A1B9A), Color(0xFFD93025)],
  );

  // ── Gradients ─────────────────────────────────────────────────
  const darkGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [gold, goldDark],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [green, greenDark],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [red, redDark],
    ),
    accent: LinearGradient(
      colors: [chartOrange, Color(0xFFFF8E53)],
    ),
    celebration: LinearGradient(
      colors: [gold, green, blue],
    ),
  );

  const lightGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [goldDark, Color(0xFFB8760A)],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A8F3C), greenDark],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD93025), redDark],
    ),
    accent: LinearGradient(
      colors: [Color(0xFFE85D2A), chartOrange],
    ),
    celebration: LinearGradient(
      colors: [goldDark, Color(0xFF1A8F3C), Color(0xFF0066CC)],
    ),
  );

  // ── UI themes ─────────────────────────────────────────────────
  const darkUi = PkUiTheme(
    skeletonBaseColor: elevated,
    skeletonHighlightColor: Color(0xFF2A2A2A),
    successColor: green,
    errorColor: red,
  );

  const lightUi = PkUiTheme(
    skeletonBaseColor: Color(0xFFE8E0D0),
    skeletonHighlightColor: Color(0xFFF5F0E5),
    successColor: Color(0xFF1A8F3C),
    errorColor: Color(0xFFD93025),
  );

  return const PkAppTheme(
    id: 'bullseye',
    name: 'Bullseye Gold',
    description: 'Black & Gold — bold, premium. Ideal for sports & gaming apps.',
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
