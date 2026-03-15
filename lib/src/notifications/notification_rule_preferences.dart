import 'package:shared_preferences/shared_preferences.dart';

/// Per-type notification preference management, generic over the app's
/// notification type enum.
///
/// Stores whether each notification type is enabled locally.
/// For Firestore-backed preferences, implement [NotificationPreferencesStore].
///
/// ```dart
/// enum MyNotifType { todo, reminder, vaccine }
///
/// final prefs = TypedNotificationPreferences<MyNotifType>(
///   values: MyNotifType.values,
///   prefix: 'my_app',
/// );
///
/// await prefs.setEnabled(MyNotifType.todo, enabled: false);
/// final enabled = await prefs.isEnabled(MyNotifType.todo);
/// ```
final class TypedNotificationPreferences<T extends Enum> {
  TypedNotificationPreferences({
    required this.values,
    this.prefix = 'pk_notif_type',
  });

  /// All enum values — needed for [enableAll], [disableAll], [getAll].
  final List<T> values;

  /// SharedPreferences key prefix.
  final String prefix;

  String _key(T type) => '${prefix}_${type.name}';

  /// Returns whether the notification type is enabled.
  /// Defaults to `true` if not set.
  Future<bool> isEnabled(T type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(type)) ?? true;
  }

  /// Sets whether the notification type is enabled.
  Future<void> setEnabled(T type, {required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(type), enabled);
  }

  /// Enable all notification types.
  Future<void> enableAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in values) {
      await prefs.setBool(_key(type), true);
    }
  }

  /// Disable all notification types.
  Future<void> disableAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in values) {
      await prefs.setBool(_key(type), false);
    }
  }

  /// Returns all stored preferences as a map.
  Future<Map<T, bool>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final type in values) type: prefs.getBool(_key(type)) ?? true,
    };
  }
}

/// Abstract interface for notification preference persistence backends.
///
/// Implement this to store preferences in Firestore, an API, or any
/// other remote backend.
abstract interface class NotificationPreferencesStore {
  /// Load all preferences for a user.
  Future<Map<String, bool>> load(String userId);

  /// Save a single preference for a user.
  Future<void> save(String userId, String type, {required bool enabled});

  /// Reset all preferences for a user.
  Future<void> reset(String userId);
}
