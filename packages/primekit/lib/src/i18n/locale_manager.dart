import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocaleKey = 'primekit_locale';

/// Stores, restores, and broadcasts the application locale without requiring
/// an app restart.
///
/// Persist locale changes to [SharedPreferences] so the user's preference
/// survives app sessions. Extends [ChangeNotifier] so it can be passed to
/// [ListenableBuilder] or [AnimatedBuilder]:
///
/// ```dart
/// // Create once at app startup
/// final localeManager = await LocaleManager.create(
///   supported: [Locale('en'), Locale('de'), Locale('fr')],
///   defaultLocale: Locale('en'),
/// );
///
/// // Wire into MaterialApp via ListenableBuilder
/// ListenableBuilder(
///   listenable: localeManager,
///   builder: (_, __) => MaterialApp(locale: localeManager.currentLocale, ...),
/// )
///
/// // Change locale at runtime
/// await localeManager.setLocale(Locale('de'));
/// ```
class LocaleManager extends ChangeNotifier {
  LocaleManager._({
    required Locale currentLocale,
    required List<Locale> supportedLocales,
  }) : _currentLocale = currentLocale,
       _supportedLocales = supportedLocales;

  Locale _currentLocale;
  List<Locale> _supportedLocales;

  /// The locale currently applied to the application.
  Locale get currentLocale => _currentLocale;

  /// The list of locales the application supports.
  List<Locale> get supportedLocales => List.unmodifiable(_supportedLocales);

  // ---------------------------------------------------------------------------
  // Factory / configuration
  // ---------------------------------------------------------------------------

  /// Creates and fully initialises a [LocaleManager].
  ///
  /// Reads any previously persisted locale preference from [SharedPreferences]
  /// and restores it if it is still in the [supported] list.
  ///
  /// ```dart
  /// final localeManager = await LocaleManager.create(
  ///   supported: [Locale('en'), Locale('es'), Locale('fr')],
  ///   defaultLocale: Locale('en'),
  /// );
  /// ```
  static Future<LocaleManager> create({
    required List<Locale> supported,
    Locale? defaultLocale,
  }) async {
    assert(supported.isNotEmpty, 'supported locales must not be empty');

    final effective = defaultLocale ?? supported.first;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLocaleKey);

    final initial = _parseLocale(stored, supported) ?? effective;

    return LocaleManager._(
      currentLocale: initial,
      supportedLocales: List.unmodifiable(supported),
    );
  }

  /// Updates the supported locale list and, optionally, the default locale.
  ///
  /// Clamps [currentLocale] to the new supported list if it is no longer
  /// present.
  Future<void> configure({
    required List<Locale> supported,
    Locale? defaultLocale,
  }) async {
    assert(supported.isNotEmpty, 'supported locales must not be empty');
    _supportedLocales = List.unmodifiable(supported);

    final fallback = defaultLocale ?? supported.first;
    final isCurrentSupported = supported.any(_localeEquals(_currentLocale));

    if (!isCurrentSupported) {
      await _applyLocale(fallback);
    } else {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Persists and applies [locale] as the current locale.
  ///
  /// Throws an [ArgumentError] if [locale] is not in [supportedLocales].
  Future<void> setLocale(Locale locale) async {
    final isSupported = _supportedLocales.any(_localeEquals(locale));
    if (!isSupported) {
      throw ArgumentError.value(
        locale,
        'locale',
        'Locale $locale is not in supportedLocales',
      );
    }
    await _applyLocale(locale);
  }

  /// Removes the persisted locale preference and restores the device system
  /// locale (the first supported locale that matches the platform locale, or
  /// the first supported locale as a safe fallback).
  Future<void> resetToSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocaleKey);

    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final matched = _supportedLocales
        .where(_localeEquals(systemLocale))
        .firstOrNull;

    _currentLocale = matched ?? _supportedLocales.first;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _applyLocale(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, _encodeLocale(locale));
    notifyListeners();
  }

  static String _encodeLocale(Locale locale) => locale.countryCode != null
      ? '${locale.languageCode}_${locale.countryCode}'
      : locale.languageCode;

  static Locale? _parseLocale(String? raw, List<Locale> supported) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('_');
    final candidate = parts.length >= 2
        ? Locale(parts[0], parts[1])
        : Locale(parts[0]);
    return supported.any(_localeEquals(candidate)) ? candidate : null;
  }

  static bool Function(Locale) _localeEquals(Locale target) =>
      (Locale l) =>
          l.languageCode == target.languageCode &&
          (l.countryCode == target.countryCode ||
              l.countryCode == null ||
              target.countryCode == null);
}
