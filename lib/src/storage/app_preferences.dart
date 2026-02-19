import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

/// A typed [SharedPreferences] wrapper for common application settings.
///
/// Covers the three most common preferences out of the box — theme mode,
/// locale, and onboarding completion — and provides a generic [set]/[get] pair
/// for arbitrary typed values (String, bool, int, double, and JSON maps).
///
/// ```dart
/// final prefs = AppPreferences.instance;
/// await prefs.setThemeMode(ThemeMode.dark);
/// final mode = await prefs.getThemeMode(); // ThemeMode.dark
/// ```
final class AppPreferences {
  AppPreferences._internal();

  static final AppPreferences _instance = AppPreferences._internal();

  /// The singleton instance.
  static AppPreferences get instance => _instance;

  // Key constants.
  static const String _keyThemeMode = 'pk_theme_mode';
  static const String _keyLocale = 'pk_locale';
  static const String _keyOnboardingComplete = 'pk_onboarding_complete';
  static const String _customKeyPrefix = 'pk_custom::';

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  /// Persists the active [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) =>
      _setString(_keyThemeMode, mode.name);

  /// Returns the persisted [ThemeMode], defaulting to [ThemeMode.system] when
  /// nothing has been stored.
  Future<ThemeMode> getThemeMode() async {
    final raw = await _getString(_keyThemeMode);
    if (raw == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  // ---------------------------------------------------------------------------
  // Locale
  // ---------------------------------------------------------------------------

  /// Persists the active locale as a BCP-47 [languageCode] (e.g. `'en'`,
  /// `'fr'`).
  Future<void> setLocale(String languageCode) =>
      _setString(_keyLocale, languageCode);

  /// Returns the persisted locale language code, or `null` if not set.
  Future<String?> getLocale() => _getString(_keyLocale);

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  /// Marks onboarding as complete (or incomplete when [value] is `false`).
  Future<void> setOnboardingComplete(bool value) =>
      _setBool(_keyOnboardingComplete, value);

  /// Returns `true` if the user has completed onboarding.
  Future<bool> isOnboardingComplete() async {
    final value = await _getBool(_keyOnboardingComplete);
    return value ?? false;
  }

  // ---------------------------------------------------------------------------
  // Generic get / set
  // ---------------------------------------------------------------------------

  /// Stores [value] under [key].
  ///
  /// Supported types: [String], [bool], [int], [double], `Map<String, dynamic>`.
  ///
  /// Throws [ArgumentError] for unsupported types.
  /// Throws [StorageException] on write failure.
  Future<void> set<T>(String key, T value) async {
    final prefKey = '$_customKeyPrefix$key';
    return switch (value) {
      final String v => _setString(prefKey, v),
      final bool v => _setBool(prefKey, v),
      final int v => _setInt(prefKey, v),
      final double v => _setDouble(prefKey, v),
      final Map<String, dynamic> v => _setJson(prefKey, v),
      _ => throw ArgumentError(
          'AppPreferences.set: unsupported type ${T.toString()}. '
          'Use String, bool, int, double, or Map<String, dynamic>.',
        ),
    };
  }

  /// Returns the value stored under [key], cast to [T], or `null` if absent.
  ///
  /// Supported types: [String], [bool], [int], [double], `Map<String, dynamic>`.
  ///
  /// Throws [ArgumentError] for unsupported types.
  /// Throws [StorageException] on read failure.
  Future<T?> get<T>(String key) async {
    final prefKey = '$_customKeyPrefix$key';
    final Object? value;
    if (T == String) {
      value = await _getString(prefKey);
    } else if (T == bool) {
      value = await _getBool(prefKey);
    } else if (T == int) {
      value = await _getInt(prefKey);
    } else if (T == double) {
      value = await _getDouble(prefKey);
    } else if (T.toString() == 'Map<String, dynamic>') {
      value = await _getJson(prefKey);
    } else {
      throw ArgumentError(
        'AppPreferences.get: unsupported type ${T.toString()}. '
        'Use String, bool, int, double, or Map<String, dynamic>.',
      );
    }
    return value as T?;
  }

  // ---------------------------------------------------------------------------
  // Remove / clear
  // ---------------------------------------------------------------------------

  /// Removes the value stored under custom [key].
  ///
  /// Throws [StorageException] on failure.
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_customKeyPrefix$key');
    } catch (e, st) {
      _handleError('remove', key, e, st);
    }
  }

  /// Removes **all** preferences managed by [AppPreferences].
  ///
  /// Throws [StorageException] on failure.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pkKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('pk_'))
          .toList(growable: false);
      await Future.wait(pkKeys.map(prefs.remove));
      PrimekitLogger.debug(
        'Cleared ${pkKeys.length} AppPreferences entries',
        tag: 'AppPreferences',
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'clearAll failed',
        tag: 'AppPreferences',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to clear all app preferences',
        code: 'APP_PREFS_CLEAR_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private typed helpers
  // ---------------------------------------------------------------------------

  Future<void> _setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e, st) {
      _handleError('setString', key, e, st);
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e, st) {
      _handleError('setBool', key, e, st);
    }
  }

  Future<void> _setInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e, st) {
      _handleError('setInt', key, e, st);
    }
  }

  Future<void> _setDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (e, st) {
      _handleError('setDouble', key, e, st);
    }
  }

  Future<void> _setJson(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (e, st) {
      _handleError('setJson', key, e, st);
    }
  }

  Future<String?> _getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e, st) {
      _handleError('getString', key, e, st);
    }
  }

  Future<bool?> _getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e, st) {
      _handleError('getBool', key, e, st);
    }
  }

  Future<int?> _getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e, st) {
      _handleError('getInt', key, e, st);
    }
  }

  Future<double?> _getDouble(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(key);
    } catch (e, st) {
      _handleError('getDouble', key, e, st);
    }
  }

  Future<Map<String, dynamic>?> _getJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e, st) {
      _handleError('getJson', key, e, st);
    }
  }

  Never _handleError(String op, String key, Object e, StackTrace st) {
    PrimekitLogger.error(
      'AppPreferences.$op failed for key "$key"',
      tag: 'AppPreferences',
      error: e,
      stackTrace: st,
    );
    throw StorageException(
      message: 'AppPreferences.$op failed for key "$key"',
      code: 'APP_PREFS_${op.toUpperCase()}_FAILED',
      cause: e,
    );
  }
}
