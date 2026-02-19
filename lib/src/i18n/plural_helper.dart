import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pluralization utilities that respect locale-specific plural rules.
///
/// English only has two plural forms (one / other), but many languages
/// (Russian, Arabic, Polish, etc.) have more complex rules. This class
/// delegates to the `intl` package's [Intl.plural] which correctly handles
/// all CLDR plural categories.
///
/// ```dart
/// PluralHelper.plural(1, 'item', 'items')       // '1 item'
/// PluralHelper.plural(3, 'item', 'items')       // '3 items'
/// PluralHelper.plural(0, 'item', 'items')       // '0 items'
///
/// PluralHelper.pluralWith(0, {
///   'zero': 'no items',
///   'one': 'item',
///   'other': 'items',
/// }) // 'no items'
/// ```
class PluralHelper {
  PluralHelper._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a correctly pluralized string for [count].
  ///
  /// When [includeCount] is `true` (default) the count is prepended:
  /// `'3 items'`. Set to `false` to get only the word form: `'items'`.
  ///
  /// [locale] overrides the current locale for plural-rule selection.
  static String plural(
    int count,
    String singular,
    String plural, {
    Locale? locale,
    bool includeCount = true,
  }) {
    final word = Intl.plural(
      count,
      one: singular,
      other: plural,
      locale: locale?.toLanguageTag(),
    );
    return includeCount ? '$count $word' : word;
  }

  /// Returns a pluralized string chosen from [forms] based on [count].
  ///
  /// [forms] must include at minimum an `'other'` key. Supported keys mirror
  /// CLDR plural categories: `'zero'`, `'one'`, `'two'`, `'few'`, `'many'`,
  /// `'other'`.
  ///
  /// When [includeCount] is `true` the count is prepended to the chosen form
  /// unless the form already starts with a digit.
  ///
  /// ```dart
  /// PluralHelper.pluralWith(0, {
  ///   'zero': 'no messages',
  ///   'one': 'message',
  ///   'other': 'messages',
  /// }) // 'no messages'  ← no count prefix because form starts with a word
  ///
  /// PluralHelper.pluralWith(5, {
  ///   'one': 'message',
  ///   'other': 'messages',
  /// }) // '5 messages'
  /// ```
  static String pluralWith(
    int count,
    Map<String, String> forms, {
    Locale? locale,
    bool includeCount = true,
  }) {
    assert(forms.containsKey('other'), "forms must include an 'other' key");

    final word = Intl.plural(
      count,
      zero: forms['zero'],
      one: forms['one'],
      two: forms['two'],
      few: forms['few'],
      many: forms['many'],
      other: forms['other']!,
      locale: locale?.toLanguageTag(),
    );

    // If the chosen form starts with a digit or the caller opted out, skip
    // the automatic count prefix.
    if (!includeCount || RegExp(r'^\d').hasMatch(word)) return word;

    // 'zero' form often reads as a full sentence ("no items"); prepend count
    // only when the form for zero starts with a letter.
    if (count == 0 && forms.containsKey('zero')) return word;

    return '$count $word';
  }
}
