import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/pk_app_theme.dart';
import '../../storage/app_preferences.dart';

/// Immutable state for the theme system.
@immutable
class PkThemeState {
  const PkThemeState({
    required this.theme,
    required this.mode,
  });

  /// The active [PkAppTheme] (e.g. PawTrack, Fresh Mint, Bullseye).
  final PkAppTheme theme;

  /// Light / dark / system mode.
  final ThemeMode mode;

  PkThemeState copyWith({
    PkAppTheme? theme,
    ThemeMode? mode,
  }) {
    return PkThemeState(
      theme: theme ?? this.theme,
      mode: mode ?? this.mode,
    );
  }
}

/// Manages the active app theme and theme mode.
///
/// Persists both values to [AppPreferences] so they survive app restarts.
///
/// ```dart
/// // In MaterialApp:
/// final themeState = ref.watch(pkThemeProvider);
/// MaterialApp(
///   theme: themeState.theme.light(),
///   darkTheme: themeState.theme.dark(),
///   themeMode: themeState.mode,
/// );
///
/// // To switch theme:
/// ref.read(pkThemeProvider.notifier).setTheme('fresh_mint');
///
/// // To switch mode:
/// ref.read(pkThemeProvider.notifier).setMode(ThemeMode.dark);
/// ```
class PkThemeNotifier extends Notifier<PkThemeState> {
  /// The default theme ID used when no theme has been persisted.
  /// Apps should override this via [pkDefaultThemeIdProvider].
  String get _defaultThemeId => ref.read(pkDefaultThemeIdProvider);

  @override
  PkThemeState build() {
    // Synchronous build — actual async restore happens in [restore].
    return PkThemeState(
      theme: PkAppTheme.byId(_defaultThemeId),
      mode: ThemeMode.system,
    );
  }

  /// Loads persisted theme and mode from [AppPreferences].
  ///
  /// Call this once during app startup (e.g. in main or an init provider).
  Future<void> restore() async {
    final prefs = AppPreferences.instance;
    final themeId = await prefs.getAppTheme() ?? _defaultThemeId;
    final mode = await prefs.getThemeMode();
    state = PkThemeState(
      theme: PkAppTheme.byId(themeId),
      mode: mode,
    );
  }

  /// Switches to a different theme by [id].
  Future<void> setTheme(String id) async {
    final theme = PkAppTheme.byId(id);
    state = state.copyWith(theme: theme);
    await AppPreferences.instance.setAppTheme(id);
  }

  /// Changes the light/dark/system mode.
  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await AppPreferences.instance.setThemeMode(mode);
  }
}

/// Override this provider to set the default theme for your app.
///
/// ```dart
/// // In your app's main.dart or providers file:
/// final pkDefaultThemeIdProvider = Provider<String>((_) => 'fresh_mint');
/// ```
final pkDefaultThemeIdProvider = Provider<String>((_) => 'pawtrack');

/// The main theme provider. Watch this in your MaterialApp.
final pkThemeProvider =
    NotifierProvider<PkThemeNotifier, PkThemeState>(PkThemeNotifier.new);

/// Convenience provider that exposes all available themes.
final pkAvailableThemesProvider =
    Provider<List<PkAppTheme>>((_) => PkAppTheme.all);
