/// Habit frequency types for PrimeKit habit tracking.
enum PkHabitFrequency {
  daily,
  weekly,
  monthly,
  custom;

  /// Serialization value.
  String get value => name;

  /// Deserialize from string, defaulting to [daily].
  static PkHabitFrequency fromString(String value) {
    return PkHabitFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PkHabitFrequency.daily,
    );
  }
}

/// Generic, immutable habit model.
///
/// Domain-agnostic: any app can use this to represent a recurring behaviour
/// the user wants to track (exercise, reading, hydration, etc.).
class PkHabit {
  final String? id;
  final String name;
  final String? description;
  final String userId;
  final DateTime createdAt;
  final PkHabitFrequency frequency;
  final List<DateTime> completionDates;
  final String? icon;
  final String? color;
  final bool isArchived;
  final DateTime? archivedAt;
  final int? targetCount;
  final Map<String, int> dailyCounts;

  const PkHabit({
    this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.createdAt,
    required this.frequency,
    this.completionDates = const [],
    this.icon,
    this.color,
    this.isArchived = false,
    this.archivedAt,
    this.targetCount,
    this.dailyCounts = const {},
  });

  /// Today's count for incremental habits, or 0/1 for binary habits.
  int get todayCount {
    if (targetCount != null) {
      final key = _dateKey(DateTime.now());
      return dailyCounts[key] ?? 0;
    }
    return isCompletedToday ? 1 : 0;
  }

  /// Whether the habit is completed for the current period.
  bool get isCompletedToday {
    if (targetCount != null) {
      return todayCount >= targetCount!;
    }
    final now = DateTime.now();
    return completionDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  /// Whether a weekly habit is completed this week.
  bool get isCompletedThisWeek {
    if (frequency != PkHabitFrequency.weekly) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return completionDates.any(
      (d) => d.isAfter(startOfWeek.subtract(const Duration(days: 1))),
    );
  }

  /// Whether a monthly habit is completed this month.
  bool get isCompletedThisMonth {
    if (frequency != PkHabitFrequency.monthly) return false;
    final now = DateTime.now();
    return completionDates.any(
      (d) => d.year == now.year && d.month == now.month,
    );
  }

  /// JSON serialization (Firestore-friendly map without Timestamp types).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'frequency': frequency.value,
      'completionDates': completionDates
          .map((d) => d.toIso8601String())
          .toList(),
      'icon': icon,
      'color': color,
      'isArchived': isArchived,
      'archivedAt': archivedAt?.toIso8601String(),
      'targetCount': targetCount,
      'dailyCounts': dailyCounts,
    };
  }

  /// Deserialize from a plain map.
  factory PkHabit.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawCounts = map['dailyCounts'] as Map<String, dynamic>?;
    final counts = rawCounts?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        {};

    return PkHabit(
      id: id ?? map['id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      userId: map['userId'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      frequency:
          PkHabitFrequency.fromString(map['frequency'] as String? ?? 'daily'),
      completionDates: (map['completionDates'] as List<dynamic>?)
              ?.map((v) => DateTime.parse(v as String))
              .toList() ??
          [],
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: map['archivedAt'] != null
          ? DateTime.parse(map['archivedAt'] as String)
          : null,
      targetCount: map['targetCount'] as int?,
      dailyCounts: counts,
    );
  }

  /// Immutable copy with optional field overrides.
  PkHabit copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    DateTime? createdAt,
    PkHabitFrequency? frequency,
    List<DateTime>? completionDates,
    String? icon,
    String? color,
    bool? isArchived,
    DateTime? archivedAt,
    int? targetCount,
    Map<String, int>? dailyCounts,
    bool clearTargetCount = false,
  }) {
    return PkHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      frequency: frequency ?? this.frequency,
      completionDates: completionDates ?? this.completionDates,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      targetCount: clearTargetCount ? null : targetCount ?? this.targetCount,
      dailyCounts: dailyCounts ?? this.dailyCounts,
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
