/// Category of a Jewish holiday.
enum PkJewishHolidayCategory {
  /// Major biblical holidays (Yom Tov).
  major,

  /// Minor holidays (Hanukkah, Purim, etc.).
  minor,

  /// Fast days (Tisha B'Av, Tzom Gedaliah, etc.).
  fast,

  /// Modern Israeli holidays (Yom HaAtzmaut, etc.).
  modern,

  /// Weekly Shabbat.
  shabbat,
}

/// An immutable representation of a Jewish holiday or observance.
///
/// ```dart
/// const holiday = PkJewishHoliday(
///   name: 'Passover',
///   hebrewName: 'פסח',
///   date: DateTime(2026, 4, 1),
///   isYomTov: true,
///   category: PkJewishHolidayCategory.major,
/// );
/// ```
class PkJewishHoliday {
  const PkJewishHoliday({
    required this.name,
    required this.hebrewName,
    required this.date,
    required this.isYomTov,
    required this.category,
    this.description,
  });

  /// English name of the holiday (e.g. "Rosh Hashanah").
  final String name;

  /// Hebrew name of the holiday (e.g. "ראש השנה").
  final String hebrewName;

  /// Gregorian date on which this holiday falls.
  final DateTime date;

  /// Whether this day has Yom Tov (festival) restrictions.
  final bool isYomTov;

  /// The category of holiday.
  final PkJewishHolidayCategory category;

  /// Optional description of the holiday.
  final String? description;

  /// Returns a copy with the given fields replaced.
  PkJewishHoliday copyWith({
    String? name,
    String? hebrewName,
    DateTime? date,
    bool? isYomTov,
    PkJewishHolidayCategory? category,
    String? description,
  }) {
    return PkJewishHoliday(
      name: name ?? this.name,
      hebrewName: hebrewName ?? this.hebrewName,
      date: date ?? this.date,
      isYomTov: isYomTov ?? this.isYomTov,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkJewishHoliday &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          hebrewName == other.hebrewName &&
          date == other.date &&
          isYomTov == other.isYomTov &&
          category == other.category;

  @override
  int get hashCode => Object.hash(name, hebrewName, date, isYomTov, category);

  @override
  String toString() => 'PkJewishHoliday($name, $date)';
}
