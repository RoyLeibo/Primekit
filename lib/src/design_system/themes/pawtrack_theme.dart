import 'package:flutter/material.dart';

import '../pk_app_theme.dart';
import '../pk_app_theme_extension.dart';
import '../pk_color_scheme.dart';
import '../pk_gradients.dart';
import '../pk_typography.dart';
import '../../ui/pk_ui_theme.dart';

PkAppTheme buildPawTrackTheme() {
  // ── Raw tokens (teal palette) ─────────────────────────────────
  const teal50 = Color(0xFFF0FDFA);
  const teal100 = Color(0xFFCCFBF1);
  const teal300 = Color(0xFF5EEAD4);
  const teal400 = Color(0xFF2DD4BF);
  const teal500 = Color(0xFF14B8A6);
  const teal600 = Color(0xFF0D9488);
  const teal700 = Color(0xFF0F766E);
  const teal800 = Color(0xFF115E59);
  const teal900 = Color(0xFF134E4A);

  // ── Raw tokens (amber palette) ────────────────────────────────
  const amber300 = Color(0xFFFCD34D);
  const amber400 = Color(0xFFFBBF24);
  const amber500 = Color(0xFFF59E0B);
  const amber600 = Color(0xFFD97706);
  const amber900 = Color(0xFF78350F);

  // ── Neutral palette ───────────────────────────────────────────
  const grey50 = Color(0xFFFAFAFA);
  const grey100 = Color(0xFFF5F5F5);
  const grey200 = Color(0xFFE5E5E5);
  const grey300 = Color(0xFFD4D4D4);
  const grey400 = Color(0xFFA3A3A3);
  const grey600 = Color(0xFF525252);
  const grey700 = Color(0xFF404040);
  const grey800 = Color(0xFF262626);
  const grey900 = Color(0xFF171717);

  // ── Semantic status ───────────────────────────────────────────
  const red500 = Color(0xFFEF4444);
  const green500 = Color(0xFF22C55E);
  const green600 = Color(0xFF16A34A);
  const warningAmber = Color(0xFFF59E0B);

  const white = Color(0xFFFFFFFF);

  // ── Typography ────────────────────────────────────────────────
  const typography = PkTypography(
    fontFamily: 'Nunito',
    displayFontFamily: 'Nunito',
  );

  // ── Light scheme ──────────────────────────────────────────────
  const lightScheme = PkColorScheme(
    primary: teal600,
    onPrimary: white,
    secondary: amber500,
    onSecondary: white,
    surface: white,
    onSurface: grey900,
    surfaceVariant: grey100,
    onSurfaceVariant: grey600,
    error: red500,
    onError: white,
    outline: grey300,
    shadow: Color(0x4D000000),
    brightness: Brightness.light,
  );

  // ── Dark scheme ───────────────────────────────────────────────
  const darkScheme = PkColorScheme(
    primary: teal400,
    onPrimary: teal900,
    secondary: amber400,
    onSecondary: amber900,
    surface: Color(0xFF1E1E1E),
    onSurface: grey50,
    surfaceVariant: grey800,
    onSurfaceVariant: grey400,
    error: red500,
    onError: white,
    outline: grey700,
    shadow: Color(0xFF000000),
    brightness: Brightness.dark,
  );

  // ── Light extension ───────────────────────────────────────────
  const lightExt = PkAppThemeExtension(
    surfaceTint: teal50,
    surfaceTintStrong: teal100,
    glassBg: Color(0x0F0D9488),
    glassBorder: Color(0x1A0D9488),
    primaryDark: teal800,
    primaryLight: teal400,
    successDark: green600,
    errorDark: Color(0xFFDC2626),
    divider: grey200,
    accent1: teal600,
    accent2: amber500,
    accent3: teal400,
    accent4: amber300,
    accent5: warningAmber,
    accent6: red500,
    textPrimary: grey900,
    textSecondary: grey600,
    textTertiary: grey400,
    avatarColors: [teal600, amber500, teal400, amber600, green500, red500],
  );

  // ── Dark extension ────────────────────────────────────────────
  const darkExt = PkAppThemeExtension(
    surfaceTint: teal900,
    surfaceTintStrong: teal800,
    glassBg: Color(0x0F2DD4BF),
    glassBorder: Color(0x1A2DD4BF),
    primaryDark: teal700,
    primaryLight: teal300,
    successDark: green500,
    errorDark: red500,
    divider: grey800,
    accent1: teal400,
    accent2: amber400,
    accent3: teal300,
    accent4: amber300,
    accent5: amber400,
    accent6: red500,
    textPrimary: grey50,
    textSecondary: grey400,
    textTertiary: grey600,
    avatarColors: [teal400, amber400, teal300, amber500, green500, red500],
  );

  // ── Gradients ─────────────────────────────────────────────────
  const lightGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [teal600, teal400],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [green500, green600],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [red500, Color(0xFFDC2626)],
    ),
    accent: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [amber500, amber600],
    ),
    celebration: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [teal400, amber400, teal600],
    ),
  );

  const darkGradients = PkGradients(
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [teal400, teal600],
    ),
    positive: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [green500, green600],
    ),
    negative: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [red500, Color(0xFFDC2626)],
    ),
    accent: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [amber400, amber600],
    ),
    celebration: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [teal300, amber300, teal500],
    ),
  );

  // ── UI themes ─────────────────────────────────────────────────
  const lightUi = PkUiTheme(
    skeletonBaseColor: grey100,
    skeletonHighlightColor: white,
    successColor: green500,
    errorColor: red500,
    warningColor: warningAmber,
  );

  const darkUi = PkUiTheme(
    skeletonBaseColor: grey800,
    skeletonHighlightColor: Color(0xFF1E1E1E),
    successColor: green500,
    errorColor: red500,
    warningColor: amber400,
  );

  return const PkAppTheme(
    id: 'pawtrack',
    name: 'PawTrack',
    description: 'Teal & Amber — friendly, rounded. Ideal for health & lifestyle apps.',
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
