/// Hebrew calendar and Jewish holiday support for PrimeKit.
///
/// This is an OPTIONAL module — it is NOT included in the main `primekit.dart`
/// barrel to avoid pulling the `kosher_dart` dependency into apps that don't
/// need it.
///
/// ```dart
/// import 'package:primekit/i18n_hebrew.dart';
///
/// final formatted = PkHebrewDateFormatter.format(DateTime.now());
/// final holidays = PkJewishHolidayService.getHolidays(from, to);
/// ```
export 'src/i18n_hebrew/i18n_hebrew.dart';
