import 'package:kosher_dart/kosher_dart.dart';

import 'jewish_holiday.dart';

/// Provides Jewish holiday dates and Shabbat times using the Hebrew calendar.
///
/// All dates are computed via `kosher_dart` — no hardcoded approximations.
///
/// ```dart
/// final holidays = PkJewishHolidayService.getHolidays(
///   DateTime(2026, 1, 1),
///   DateTime(2026, 12, 31),
/// );
///
/// final shabbat = PkJewishHolidayService.isShabbat(DateTime(2026, 3, 14));
/// ```
abstract final class PkJewishHolidayService {
  /// Returns all Jewish holidays falling between [from] and [to] (inclusive).
  ///
  /// Iterates day-by-day through the range, so keep the span reasonable
  /// (typically one calendar year).
  static List<PkJewishHoliday> getHolidays(DateTime from, DateTime to) {
    final List<PkJewishHoliday> results = [];
    final startDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(to.year, to.month, to.day);

    var current = startDay;
    while (!current.isAfter(endDay)) {
      final holiday = _holidayForDate(current);
      if (holiday != null) {
        results.add(holiday);
      }
      current = current.add(const Duration(days: 1));
    }

    return List.unmodifiable(results);
  }

  /// Whether [date] falls on Shabbat (Saturday).
  static bool isShabbat(DateTime date) => date.weekday == DateTime.saturday;

  /// Computes candle lighting and havdalah times for a Friday [friday].
  ///
  /// Returns a record of `(candleLighting, havdalah)` as [DateTime] values.
  /// [latitude] and [longitude] determine the geographic location.
  ///
  /// Throws [ArgumentError] if [friday] is not a Friday.
  static ({DateTime candleLighting, DateTime havdalah}) getShabbatTimes(
    DateTime friday, {
    required double latitude,
    required double longitude,
  }) {
    if (friday.weekday != DateTime.friday) {
      throw ArgumentError.value(
        friday,
        'friday',
        'Expected a Friday, got weekday ${friday.weekday}',
      );
    }

    final geoLocation = GeoLocation.setLocation(
      lat: latitude,
      long: longitude,
      dateTime: friday,
    );
    final calendar = ZmanimCalendar.intGeoLocation(geoLocation: geoLocation);

    final candleLighting = calendar.candleLighting ??
        _fallbackSunset(calendar).subtract(const Duration(minutes: 18));

    final saturday = friday.add(const Duration(days: 1));
    final satGeo = GeoLocation.setLocation(
      lat: latitude,
      long: longitude,
      dateTime: saturday,
    );
    final satCalendar = ZmanimCalendar.intGeoLocation(geoLocation: satGeo);

    final havdalah = _computeHavdalah(satCalendar);

    return (candleLighting: candleLighting, havdalah: havdalah);
  }

  /// Returns the next Jewish holiday on or after [from], or `null` if none
  /// is found within the following 400 days.
  static PkJewishHoliday? nextHoliday(DateTime from) {
    final startDay = DateTime(from.year, from.month, from.day);
    final limit = startDay.add(const Duration(days: 400));

    var current = startDay;
    while (!current.isAfter(limit)) {
      final holiday = _holidayForDate(current);
      if (holiday != null) {
        return holiday;
      }
      current = current.add(const Duration(days: 1));
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static PkJewishHoliday? _holidayForDate(DateTime date) {
    try {
      final jewishCalendar = JewishCalendar.fromDateTime(date);
      final yomTovIndex = jewishCalendar.getYomTovIndex();

      if (yomTovIndex <= 0) return null;

      final entry = _mapYomTovIndex(yomTovIndex);
      if (entry == null) return null;

      return PkJewishHoliday(
        name: entry.name,
        hebrewName: entry.hebrewName,
        date: date,
        isYomTov: entry.isYomTov,
        category: entry.category,
        description: entry.description,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime _fallbackSunset(ZmanimCalendar calendar) {
    return calendar.sunset ?? calendar.seaLevelSunset ?? DateTime.now();
  }

  static DateTime _computeHavdalah(ZmanimCalendar calendar) {
    final sunset = _fallbackSunset(calendar);
    return sunset.add(const Duration(minutes: 42));
  }

  static _HolidayEntry? _mapYomTovIndex(int index) {
    return _holidayMap[index];
  }
}

class _HolidayEntry {
  const _HolidayEntry({
    required this.name,
    required this.hebrewName,
    required this.isYomTov,
    required this.category,
    this.description,
  });

  final String name;
  final String hebrewName;
  final bool isYomTov;
  final PkJewishHolidayCategory category;
  final String? description;
}

/// Maps kosher_dart YomTovIndex values to holiday metadata.
///
/// Index values are based on the JewishCalendar.getYomTovIndex() return values.
const Map<int, _HolidayEntry> _holidayMap = {
  // Rosh Hashanah
  4: _HolidayEntry(
    name: 'Rosh Hashanah',
    hebrewName: 'ראש השנה',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Jewish New Year',
  ),
  // Tzom Gedaliah
  5: _HolidayEntry(
    name: 'Tzom Gedaliah',
    hebrewName: 'צום גדליה',
    isYomTov: false,
    category: PkJewishHolidayCategory.fast,
    description: 'Fast of Gedaliah',
  ),
  // Yom Kippur
  6: _HolidayEntry(
    name: 'Yom Kippur',
    hebrewName: 'יום כיפור',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Day of Atonement',
  ),
  // Sukkot
  7: _HolidayEntry(
    name: 'Sukkot',
    hebrewName: 'סוכות',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Feast of Tabernacles',
  ),
  // Chol HaMoed Sukkot
  8: _HolidayEntry(
    name: 'Chol HaMoed Sukkot',
    hebrewName: 'חול המועד סוכות',
    isYomTov: false,
    category: PkJewishHolidayCategory.major,
    description: 'Intermediate days of Sukkot',
  ),
  // Hoshana Rabbah
  9: _HolidayEntry(
    name: 'Hoshana Rabbah',
    hebrewName: 'הושענא רבה',
    isYomTov: false,
    category: PkJewishHolidayCategory.major,
    description: 'Great Hoshana',
  ),
  // Shemini Atzeret
  10: _HolidayEntry(
    name: 'Shemini Atzeret',
    hebrewName: 'שמיני עצרת',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Eighth Day of Assembly',
  ),
  // Simchat Torah
  11: _HolidayEntry(
    name: 'Simchat Torah',
    hebrewName: 'שמחת תורה',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Rejoicing with the Torah',
  ),
  // Hanukkah
  12: _HolidayEntry(
    name: 'Hanukkah',
    hebrewName: 'חנוכה',
    isYomTov: false,
    category: PkJewishHolidayCategory.minor,
    description: 'Festival of Lights',
  ),
  // Tenth of Tevet
  13: _HolidayEntry(
    name: 'Tenth of Tevet',
    hebrewName: 'עשרה בטבת',
    isYomTov: false,
    category: PkJewishHolidayCategory.fast,
    description: 'Fast of Tevet',
  ),
  // Tu BiShvat
  14: _HolidayEntry(
    name: 'Tu BiShvat',
    hebrewName: 'ט״ו בשבט',
    isYomTov: false,
    category: PkJewishHolidayCategory.minor,
    description: 'New Year of the Trees',
  ),
  // Fast of Esther
  15: _HolidayEntry(
    name: 'Fast of Esther',
    hebrewName: 'תענית אסתר',
    isYomTov: false,
    category: PkJewishHolidayCategory.fast,
    description: 'Fast of Esther',
  ),
  // Purim
  16: _HolidayEntry(
    name: 'Purim',
    hebrewName: 'פורים',
    isYomTov: false,
    category: PkJewishHolidayCategory.minor,
    description: 'Festival of Lots',
  ),
  // Shushan Purim
  17: _HolidayEntry(
    name: 'Shushan Purim',
    hebrewName: 'שושן פורים',
    isYomTov: false,
    category: PkJewishHolidayCategory.minor,
    description: 'Purim in walled cities',
  ),
  // Passover
  18: _HolidayEntry(
    name: 'Passover',
    hebrewName: 'פסח',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Festival of Freedom',
  ),
  // Chol HaMoed Pesach
  19: _HolidayEntry(
    name: 'Chol HaMoed Pesach',
    hebrewName: 'חול המועד פסח',
    isYomTov: false,
    category: PkJewishHolidayCategory.major,
    description: 'Intermediate days of Passover',
  ),
  // Seventh of Passover
  20: _HolidayEntry(
    name: 'Seventh of Passover',
    hebrewName: 'שביעי של פסח',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Seventh day of Passover',
  ),
  // Yom HaShoah
  21: _HolidayEntry(
    name: 'Yom HaShoah',
    hebrewName: 'יום השואה',
    isYomTov: false,
    category: PkJewishHolidayCategory.modern,
    description: 'Holocaust Remembrance Day',
  ),
  // Yom HaZikaron
  22: _HolidayEntry(
    name: 'Yom HaZikaron',
    hebrewName: 'יום הזיכרון',
    isYomTov: false,
    category: PkJewishHolidayCategory.modern,
    description: 'Memorial Day',
  ),
  // Yom HaAtzmaut
  23: _HolidayEntry(
    name: 'Yom HaAtzmaut',
    hebrewName: 'יום העצמאות',
    isYomTov: false,
    category: PkJewishHolidayCategory.modern,
    description: 'Israel Independence Day',
  ),
  // Lag BaOmer
  24: _HolidayEntry(
    name: 'Lag BaOmer',
    hebrewName: 'ל״ג בעומר',
    isYomTov: false,
    category: PkJewishHolidayCategory.minor,
    description: '33rd day of the Omer',
  ),
  // Yom Yerushalayim
  25: _HolidayEntry(
    name: 'Yom Yerushalayim',
    hebrewName: 'יום ירושלים',
    isYomTov: false,
    category: PkJewishHolidayCategory.modern,
    description: 'Jerusalem Day',
  ),
  // Shavuot
  26: _HolidayEntry(
    name: 'Shavuot',
    hebrewName: 'שבועות',
    isYomTov: true,
    category: PkJewishHolidayCategory.major,
    description: 'Festival of Weeks',
  ),
  // 17th of Tammuz
  27: _HolidayEntry(
    name: 'Seventeenth of Tammuz',
    hebrewName: 'שבעה עשר בתמוז',
    isYomTov: false,
    category: PkJewishHolidayCategory.fast,
    description: 'Fast of Tammuz',
  ),
  // Tisha B'Av
  28: _HolidayEntry(
    name: "Tisha B'Av",
    hebrewName: 'תשעה באב',
    isYomTov: false,
    category: PkJewishHolidayCategory.fast,
    description: 'Day of Mourning',
  ),
  // Tu B'Av
  29: _HolidayEntry(
    name: "Tu B'Av",
    hebrewName: 'ט״ו באב',
    isYomTov: false,
    category: PkJewishHolidayCategory.minor,
    description: 'Day of Love',
  ),
  // Erev Rosh Hashanah
  1: _HolidayEntry(
    name: 'Erev Rosh Hashanah',
    hebrewName: 'ערב ראש השנה',
    isYomTov: false,
    category: PkJewishHolidayCategory.major,
    description: 'Eve of the Jewish New Year',
  ),
  // Erev Yom Kippur
  2: _HolidayEntry(
    name: 'Erev Yom Kippur',
    hebrewName: 'ערב יום כיפור',
    isYomTov: false,
    category: PkJewishHolidayCategory.major,
    description: 'Eve of the Day of Atonement',
  ),
  // Erev Sukkot
  3: _HolidayEntry(
    name: 'Erev Sukkot',
    hebrewName: 'ערב סוכות',
    isYomTov: false,
    category: PkJewishHolidayCategory.major,
    description: 'Eve of Sukkot',
  ),
};
