import 'package:flutter/material.dart';

import '../pk_app_theme.dart';
import '../pk_app_theme_extension.dart';
import '../pk_color_scheme.dart';
import '../pk_gradients.dart';
import '../pk_typography.dart';
import '../../ui/pk_ui_theme.dart';

PkAppTheme buildFreshMintTheme() {
  // ── Brand colors ──────────────────────────────────────────────
  const primary = Color(0xFF10B981);
  const primaryLight = Color(0xFF6EE7B7);
  const primaryDark = Color(0xFF059669);
  const secondary = Color(0xFF84CC16);
  const accent = Color(0xFF0EA5E9);
  const purple = Color(0xFF8B5CF6);

  // ── Status ────────────────────────────────────────────────────
  const success = Color(0xFF10B981);
  const successDark = Color(0xFF059669);
  const error = Color(0xFFEF4444);
  const errorDark = Color(0xFFDC2626);
  const warning = Color(0xFFF59E0B);

  // ── Light surfaces ────────────────────────────────────────────
  const surfaceLight = Color(0xFFFFFFFF);
  const surfaceTintLight = Color(0xFFDCFCE7);
  const surfaceTintStrongLight = Color(0xFFBBF7D0);
  const dividerLight = Color(0xFFE2E8F0);

  // ── Light text ────────────────────────────────────────────────
  const textPrimaryLight = Color(0xFF064E3B);
  const textSecondaryLight = Color(0xFF6B7280);
  const textDisabledLight = Color(0xFF9CA3AF);

  // ── Dark surfaces ─────────────────────────────────────────────
  const surfaceDark = Color(0xFF161B22);
  const surfaceTintDark = Color(0xFF21262D);
  const surfaceTintStrongDark = Color(0xFF30363D);
  const dividerDark = Color(0xFF30363D);

  // ── Dark text ─────────────────────────────────────────────────
  const textPrimaryDark = Color(0xFFE6EAF0);
  const textSecondaryDark = Color(0xFF8B949E);
  const textDisabledDark = Color(0xFF6E7681);

  // ── Dark status ───────────────────────────────────────────────
  const darkError = Color(0xFFF87171);

  const white = Color(0xFFFFFFFF);

  // ── Typography (Poppins display, Inter body) ──────────────────
  const typography = PkTypography(
    fontFamily: 'Inter',
    displayFontFamily: 'Poppins',
  );

  // ── Light scheme ──────────────────────────────────────────────
  const lightScheme = PkColorScheme(
    primary: primary,
    onPrimary: white,
    secondary: secondary,
    onSecondary: white,
    surface: surfaceLight,
    onSurface: textPrimaryLight,
    surfaceVariant: surfaceTintLight,
    onSurfaceVariant: textSecondaryLight,
    error: error,
    onError: white,
    outline: dividerLight,
    shadow: Color(0x0F10B981),
    brightness: Brightness.light,
  );

  // ── Dark scheme ───────────────────────────────────────────────
  const darkScheme = PkColorScheme(
    primary: primary,
    onPrimary: Color(0xFF064E3B),
    secondary: secondary,
    onSecondary: Color(0xFF1A2E00),
    surface: surfaceDark,
    onSurface: textPrimaryDark,
    surfaceVariant: surfaceTintDark,
    onSurfaceVariant: textSecondaryDark,
    error: darkError,
    onError: white,
    outline: dividerDark,
    shadow: Color(0x33000000),
    brightness: Brightness.dark,
  );

  // ── Light extension ───────────────────────────────────────────
  const lightExt = PkAppThemeExtension(
    surfaceTint: surfaceTintLight,
    surfaceTintStrong: surfaceTintStrongLight,
    glassBg: Color(0x0F10B981),
    glassBorder: Color(0x1A10B981),
    primaryDark: primaryDark,
    primaryLight: primaryLight,
    successDark: successDark,
    errorDark: errorDark,
    divider: dividerLight,
    accent1: primary,
    accent2: secondary,
    accent3: accent,
    accent4: purple,
    accent5: warning,
    accent6: error,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    textTertiary: textDisabledLight,
    avatarColors: [primary, secondary, accent, purple, warning, error],
  );

  // ── Dark extension ────────────────────────────────────────────
  const darkExt = PkAppThemeExtension(
    surfaceTint: surfaceTintDark,
    surfaceTintStrong: surfaceTintStrongDark,
    glassBg: Color(0x0F10B981),
    glassBorder: Color(0x1A10B981),
    primaryDark: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    successDark: successDark,
    errorDark: darkError,
    divider: dividerDark,
    accent1: primary,
    accent2: secondary,
    accent3: accent,
    accent4: purple,
    accent5: warning,
    accent6: darkError,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    textTertiary: textDisabledDark,
    avatarColors: [primary, secondary, accent, purple, warning, darkError],
  );

  // ── Gradients ─────────────────────────────────────────────────
  const lightGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF84CC16)],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    accent: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
    ),
    celebration: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF84CC16), Color(0xFF0EA5E9)],
    ),
  );

  const darkGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E5940), Color(0xFF6D8020)],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF87171), Color(0xFFEF4444)],
    ),
    accent: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
    ),
    celebration: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF84CC16), Color(0xFF0EA5E9)],
    ),
  );

  // ── UI themes ─────────────────────────────────────────────────
  const lightUi = PkUiTheme(
    skeletonBaseColor: Color(0xFFE0E0E0),
    skeletonHighlightColor: Color(0xFFF5F5F5),
    successColor: success,
    errorColor: error,
  );

  const darkUi = PkUiTheme(
    skeletonBaseColor: surfaceTintDark,
    skeletonHighlightColor: surfaceTintStrongDark,
    successColor: primary,
    errorColor: darkError,
  );

  return const PkAppTheme(
    id: 'fresh_mint',
    name: 'Fresh Mint',
    description: 'Emerald & Lime — fresh, vibrant. Ideal for social & finance apps.',
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
