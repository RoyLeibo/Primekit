import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

/// Abstract interface for token persistence.
///
/// Depend on this interface to facilitate testing with mock implementations.
abstract class TokenStoreBase {
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<bool> hasValidToken();
  Future<void> clearAll();
}

/// Secure, singleton storage for JWT access and refresh tokens.
///
/// Persists tokens using [flutter_secure_storage], which uses the platform
/// Keychain (iOS/macOS) or EncryptedSharedPreferences (Android).
///
/// Includes a lightweight JWT expiry check that decodes the `exp` claim from
/// the token payload **without** performing cryptographic verification — use
/// this only to decide whether to attempt a refresh, not to trust token
/// contents.
///
/// ```dart
/// final store = TokenStore.instance;
/// await store.saveAccessToken(accessToken);
/// final valid = await store.hasValidToken();
/// ```
final class TokenStore implements TokenStoreBase {
  TokenStore._internal();

  static final TokenStore _instance = TokenStore._internal();

  /// The singleton instance.
  static TokenStore get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyAccessToken = 'pk_access_token';
  static const String _keyRefreshToken = 'pk_refresh_token';

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Persists [token] as the access token.
  ///
  /// Throws [StorageException] on failure.
  @override
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _keyAccessToken, value: token);
      PrimekitLogger.debug('Access token saved', tag: 'TokenStore');
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to save access token',
        tag: 'TokenStore',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to persist access token',
        code: 'SAVE_ACCESS_TOKEN_FAILED',
        cause: e,
      );
    }
  }

  /// Persists [token] as the refresh token.
  ///
  /// Throws [StorageException] on failure.
  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
      PrimekitLogger.debug('Refresh token saved', tag: 'TokenStore');
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to save refresh token',
        tag: 'TokenStore',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to persist refresh token',
        code: 'SAVE_REFRESH_TOKEN_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the stored access token, or `null` if none exists.
  ///
  /// Throws [StorageException] on failure.
  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to read access token',
        tag: 'TokenStore',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to read access token',
        code: 'READ_ACCESS_TOKEN_FAILED',
        cause: e,
      );
    }
  }

  /// Returns the stored refresh token, or `null` if none exists.
  ///
  /// Throws [StorageException] on failure.
  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to read refresh token',
        tag: 'TokenStore',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to read refresh token',
        code: 'READ_REFRESH_TOKEN_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Validity
  // ---------------------------------------------------------------------------

  /// Returns `true` if a non-expired access token is stored.
  ///
  /// Expiry is determined by reading the `exp` claim from the JWT payload and
  /// comparing it to the current UTC time. A 30-second clock-skew buffer is
  /// applied so tokens are considered expired slightly before the server would
  /// reject them.
  ///
  /// Returns `false` when no token is stored or when the token cannot be
  /// decoded.
  @override
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !_isTokenExpired(token);
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  /// Removes both the access and refresh tokens from secure storage.
  ///
  /// Throws [StorageException] on failure.
  @override
  Future<void> clearAll() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
      ]);
      PrimekitLogger.debug('All tokens cleared', tag: 'TokenStore');
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to clear tokens',
        tag: 'TokenStore',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to clear stored tokens',
        code: 'CLEAR_TOKENS_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // JWT helpers (no signature verification — expiry only)
  // ---------------------------------------------------------------------------

  /// Returns `true` when [token] has expired or cannot be decoded.
  ///
  /// Applies a 30-second clock-skew buffer: a token is considered expired when
  /// `exp - 30s <= now`.
  bool _isTokenExpired(String token) {
    try {
      final payload = _decodePayload(token);
      final exp = payload['exp'];
      if (exp == null) {
        // No expiry claim — treat as never-expiring.
        return false;
      }
      if (exp is! num) {
        PrimekitLogger.warning(
          'JWT exp claim is not numeric: $exp',
          tag: 'TokenStore',
        );
        return true;
      }
      const clockSkewSeconds = 30;
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      final now = DateTime.now().toUtc();
      return now.isAfter(
        expiresAt.subtract(const Duration(seconds: clockSkewSeconds)),
      );
    } on Exception catch (e) {
      PrimekitLogger.warning(
        'Could not decode JWT expiry; treating as expired',
        tag: 'TokenStore',
        error: e,
      );
      return true;
    }
  }

  /// Decodes the payload section of [token] and returns it as a map.
  ///
  /// Throws [FormatException] when [token] does not have the expected
  /// `header.payload.signature` structure.
  Map<String, dynamic> _decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token does not have 3 JWT segments');
    }

    // Base64url → base64 normalization (pad to multiple of 4).
    final normalized = base64Url.normalize(parts[1]);
    final payloadBytes = base64Url.decode(normalized);
    final payloadJson = utf8.decode(payloadBytes);
    return jsonDecode(payloadJson) as Map<String, dynamic>;
  }
}
