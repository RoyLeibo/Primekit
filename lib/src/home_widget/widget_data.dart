import 'package:flutter/foundation.dart';

/// Base class for data pushed to a home screen widget.
///
/// Subclass this to define the shape of data your widget displays.
///
/// ```dart
/// class PetWidgetData extends PkWidgetData {
///   const PetWidgetData({
///     required this.upcomingItems,
///     required this.overdueCount,
///     required super.lastUpdated,
///   });
///
///   final List<String> upcomingItems;
///   final int overdueCount;
///
///   @override
///   Map<String, dynamic> toWidgetMap() => {
///     'upcoming_items': upcomingItems.take(3).join('\n'),
///     'overdue_count': overdueCount,
///     'last_updated': lastUpdated.toIso8601String(),
///   };
/// }
/// ```
@immutable
abstract class PkWidgetData {
  /// Creates a [PkWidgetData] snapshot.
  const PkWidgetData({required this.lastUpdated});

  /// Timestamp of when this data was generated.
  final DateTime lastUpdated;

  /// Serializes this data into a flat key-value map suitable for
  /// `home_widget` storage.
  ///
  /// Keys must be strings. Values should be primitives (`String`, `int`,
  /// `double`, `bool`) since the home_widget package stores them via
  /// platform `SharedPreferences` / `UserDefaults`.
  Map<String, dynamic> toWidgetMap();
}
