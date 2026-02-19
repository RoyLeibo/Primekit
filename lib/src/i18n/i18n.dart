/// i18n — Locale management, date/currency formatting, and pluralisation
/// utilities for Primekit.
///
/// Requires the `intl` and `shared_preferences` packages.
///
/// ```dart
/// import 'package:primekit/primekit.dart';
/// // or tree-shake to just this module:
/// import 'package:primekit/src/i18n/i18n.dart';
/// ```
library primekit_i18n;

export 'currency_formatter.dart';
export 'date_formatter.dart';
export 'locale_manager.dart';
export 'plural_helper.dart';
