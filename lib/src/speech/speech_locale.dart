import 'dart:ui' as ui;

/// An immutable value type representing a speech recognition locale.
///
/// Use the factory constructors for common locales, or create a custom
/// instance by providing [localeId] and [name] directly.
final class PkSpeechLocale {
  /// Creates a speech locale with the given [localeId] and [name].
  const PkSpeechLocale({
    required this.localeId,
    required this.name,
  });

  /// The BCP-47 locale identifier (e.g. `en-US`, `he-IL`).
  final String localeId;

  /// A human-readable name for this locale (e.g. `English (US)`).
  final String name;

  /// American English locale.
  factory PkSpeechLocale.english() => const PkSpeechLocale(
        localeId: 'en-US',
        name: 'English (US)',
      );

  /// Hebrew (Israel) locale.
  factory PkSpeechLocale.hebrew() => const PkSpeechLocale(
        localeId: 'he-IL',
        name: 'Hebrew',
      );

  /// Determines the locale from the system's current locale.
  ///
  /// Falls back to English if the system locale is not recognized.
  factory PkSpeechLocale.fromSystem() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final languageCode = systemLocale.languageCode;

    if (languageCode == 'he' || languageCode == 'iw') {
      return PkSpeechLocale.hebrew();
    }

    return PkSpeechLocale.english();
  }

  /// Creates a locale from a Flutter [ui.Locale].
  factory PkSpeechLocale.fromLocale(ui.Locale locale) {
    final languageCode = locale.languageCode;

    if (languageCode == 'he' || languageCode == 'iw') {
      return PkSpeechLocale.hebrew();
    }

    final countryCode = locale.countryCode;
    final id =
        countryCode != null ? '$languageCode-$countryCode' : languageCode;

    return PkSpeechLocale(
      localeId: id,
      name: id,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkSpeechLocale && localeId == other.localeId;

  @override
  int get hashCode => localeId.hashCode;

  @override
  String toString() => 'PkSpeechLocale($localeId, $name)';
}
