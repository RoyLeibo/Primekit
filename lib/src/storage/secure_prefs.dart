import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

/// Abstract interface for secure key-value persistence.
///
/// Depend on this interface to facilitate testing with mock implementations.
abstract class SecurePrefsBase {
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setJson(String key, Map<String, dynamic> json);
  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> remove(String key);
  Future<void> clearAll();
}

/// A typed, singleton wrapper around [FlutterSecureStorage] that provides
/// convenience methods for storing primitive and JSON values securely.
///
/// All values are stored as strings internally, with type coercion applied
/// on read. For non-sensitive data that does not need encryption prefer
/// [AppPreferences] (backed by [SharedPreferences]).
///
/// ```dart
/// final prefs = SecurePrefs.instance;
/// await prefs.setString('user_token', token);
/// final token = await prefs.getString('user_token');
/// ```
final class SecurePrefs implements SecurePrefsBase {
  SecurePrefs._internal();

  static final SecurePrefs _instance = SecurePrefs._internal();

  /// The singleton instance.
  static SecurePrefs get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Stores [value] under [key] as a raw string.
  @override
  Future<void> setString(String key, String value) =>
      _write(key, value);

  /// Stores [value] under [key] as `'true'` or `'false'`.
  @override
  Future<void> setBool(String key, bool value) =>
      _write(key, value.toString());

  /// Stores [value] under [key] as its decimal string representation.
  @override
  Future<void> setInt(String key, int value) =>
      _write(key, value.toString());

  /// Stores [value] under [key] as its string representation.
  @override
  Future<void> setDouble(String key, double value) =>
      _write(key, value.toString());

  /// JSON-encodes [json] and stores the result under [key].
  @override
  Future<void> setJson(String key, Map<String, dynamic> json) =>
      _write(key, jsonEncode(json));

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the string stored under [key], or `null` if absent.
  @override
  Future<String?> getString(String key) => _read(key);

  /// Returns the boolean stored under [key], or `null` if absent.
  ///
  /// Parses `'true'` → `true`; anything else → `false`.
  @override
  Future<bool?> getBool(String key) async {
    final raw = await _read(key);
    if (raw == null) return null;
    return raw == 'true';
  }

  /// Returns the integer stored under [key], or `null` if absent or
  /// unparseable.
  @override
  Future<int?> getInt(String key) async {
    final raw = await _read(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  /// Returns the double stored under [key], or `null` if absent or
  /// unparseable.
  @override
  Future<double?> getDouble(String key) async {
    final raw = await _read(key);
    if (raw == null) return null;
    return double.tryParse(raw);
  }

  /// Returns the JSON map stored under [key], or `null` if absent or
  /// malformed.
  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await _read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      PrimekitLogger.warning(
        'SecurePrefs.getJson: decoded value for "$key" is not a Map',
        tag: 'SecurePrefs',
      );
      return null;
    } on Exception catch (e) {
      PrimekitLogger.warning(
        'SecurePrefs.getJson: failed to decode JSON for key "$key"',
        tag: 'SecurePrefs',
        error: e,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Remove / clear
  // ---------------------------------------------------------------------------

  /// Removes the value stored under [key].
  ///
  /// No-op when [key] does not exist.
  @override
  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
      PrimekitLogger.debug('Removed key "$key"', tag: 'SecurePrefs');
    } on Exception catch (e, st) {
      _handleError('remove', key, e, st);
    }
  }

  /// Removes all values from secure storage.
  @override
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      PrimekitLogger.debug('Cleared all secure prefs', tag: 'SecurePrefs');
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'clearAll failed',
        tag: 'SecurePrefs',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to clear all secure preferences',
        code: 'SECURE_PREFS_CLEAR_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      PrimekitLogger.verbose('Wrote key "$key"', tag: 'SecurePrefs');
    } catch (e, st) {
      _handleError('write', key, e, st);
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, st) {
      _handleError('read', key, e, st);
    }
  }

  Never _handleError(String operation, String key, Object e, StackTrace st) {
    PrimekitLogger.error(
      'SecurePrefs.$operation failed for key "$key"',
      tag: 'SecurePrefs',
      error: e,
      stackTrace: st,
    );
    throw StorageException(
      message: 'SecurePrefs.$operation failed for key "$key"',
      code: 'SECURE_PREFS_${operation.toUpperCase()}_FAILED',
      cause: e,
    );
  }
}
