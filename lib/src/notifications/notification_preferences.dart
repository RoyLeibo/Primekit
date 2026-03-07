import 'package:shared_preferences/shared_preferences.dart';

/// Per-user notification preference management.
///
/// Store whether each notification type is enabled, persisted locally.
///
/// ```dart
/// await NotificationPreferences.instance.setEnabled('new_message', enabled: false);
/// final enabled = await NotificationPreferences.instance.isEnabled('new_message');
/// ```
class NotificationPreferences {
  NotificationPreferences._();

  static final NotificationPreferences instance = NotificationPreferences._();

  static const String _prefix = 'pk_notif_pref_';

  /// Sets whether a notification type is enabled.
  Future<void> setEnabled(String type, {required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$type', enabled);
  }

  /// Returns whether a notification type is enabled.
  /// Defaults to [defaultValue] (true) if not set.
  Future<bool> isEnabled(String type, {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$type') ?? defaultValue;
  }

  /// Returns all stored preferences as a map.
  Future<Map<String, bool>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    return {
      for (final k in keys) k.substring(_prefix.length): prefs.getBool(k)!,
    };
  }

  /// Resets all preferences to defaults (removes stored values).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
