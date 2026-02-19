import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../storage/secure_prefs.dart' show SecurePrefs, SecurePrefsBase;
import 'token_store.dart' show TokenStore, TokenStoreBase;

// ---------------------------------------------------------------------------
// Session state
// ---------------------------------------------------------------------------

/// Represents the current authentication state of the application.
sealed class SessionState {
  const SessionState();
}

/// The session state is being restored from persisted storage.
final class SessionLoading extends SessionState {
  const SessionLoading();
}

/// The user is not authenticated.
final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// The user is authenticated.
final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({
    required this.userId,
    this.userData,
  });

  /// The authenticated user's identifier.
  final String userId;

  /// Optional arbitrary user profile data returned from the auth provider.
  final Map<String, dynamic>? userData;

  @override
  String toString() =>
      'SessionAuthenticated(userId: $userId, userData: $userData)';
}

// ---------------------------------------------------------------------------
// SessionStateProvider — abstract interface used by ProtectedRouteGuard
// ---------------------------------------------------------------------------

/// Read-only interface that exposes the current [SessionState].
///
/// Depend on this interface instead of [SessionManager] when you need to
/// observe authentication state without holding a reference to the full
/// manager. This enables easy test mocking.
abstract class SessionStateProvider {
  /// The current session state.
  SessionState get state;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated;
}

// ---------------------------------------------------------------------------
// SessionManager
// ---------------------------------------------------------------------------

/// Manages user authentication state across the application lifecycle.
///
/// Extends [ChangeNotifier] so widgets can rebuild reactively, and also
/// exposes a [stateStream] for non-widget consumers (e.g. Bloc/Riverpod
/// bridges).
///
/// State is persisted across restarts: on construction the manager restores
/// the previous session from [SecurePrefs] and validates token expiry via
/// [TokenStore].
///
/// ```dart
/// // In main()
/// final session = SessionManager.instance;
/// await session.restore();
///
/// // In a widget
/// final session = context.watch<SessionManager>();
/// if (session.isAuthenticated) { ... }
/// ```
final class SessionManager extends ChangeNotifier implements SessionStateProvider {
  SessionManager._internal({
    required TokenStoreBase tokenStore,
    required SecurePrefsBase securePrefs,
  })  : _tokenStore = tokenStore,
        _securePrefs = securePrefs;

  static SessionManager? _instance;

  /// Returns the singleton, constructing it with default dependencies on the
  /// first call. Override dependencies only for testing via [resetForTesting].
  static SessionManager get instance {
    _instance ??= SessionManager._internal(
      tokenStore: TokenStore.instance,
      securePrefs: SecurePrefs.instance,
    );
    return _instance!;
  }

  /// Replaces the singleton with a test double. Call in test `setUp`.
  @visibleForTesting
  static void resetForTesting({
    required TokenStoreBase tokenStore,
    required SecurePrefsBase securePrefs,
  }) {
    _instance?.dispose();
    _instance = SessionManager._internal(
      tokenStore: tokenStore,
      securePrefs: securePrefs,
    );
  }

  final TokenStoreBase _tokenStore;
  final SecurePrefsBase _securePrefs;

  static const String _keyUserId = 'pk_session_user_id';
  static const String _keyUserData = 'pk_session_user_data';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  SessionState _state = const SessionLoading();
  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();

  /// The current session state.
  @override
  SessionState get state => _state;

  /// A broadcast stream that emits every time [state] changes.
  Stream<SessionState> get stateStream => _stateController.stream;

  /// Whether the user is currently authenticated.
  @override
  bool get isAuthenticated => _state is SessionAuthenticated;

  /// The authenticated user's identifier, or `null` when unauthenticated.
  String? get currentUserId =>
      _state is SessionAuthenticated
          ? (_state as SessionAuthenticated).userId
          : null;

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Restores session state from persisted storage.
  ///
  /// Call this once during app startup (before [runApp]) to recover an active
  /// session or transition to [SessionUnauthenticated].
  Future<void> restore() async {
    _emitState(const SessionLoading());

    try {
      final hasValid = await _tokenStore.hasValidToken();
      if (!hasValid) {
        PrimekitLogger.debug(
          'No valid token on restore — unauthenticated',
          tag: 'SessionManager',
        );
        _emitState(const SessionUnauthenticated());
        return;
      }

      final userId = await _securePrefs.getString(_keyUserId);
      if (userId == null) {
        PrimekitLogger.debug(
          'Valid token found but no persisted userId — clearing tokens',
          tag: 'SessionManager',
        );
        await _tokenStore.clearAll();
        _emitState(const SessionUnauthenticated());
        return;
      }

      final userDataJson = await _securePrefs.getJson(_keyUserData);
      _emitState(
        SessionAuthenticated(userId: userId, userData: userDataJson),
      );
      PrimekitLogger.info(
        'Session restored for userId: $userId',
        tag: 'SessionManager',
      );
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Failed to restore session',
        tag: 'SessionManager',
        error: e,
        stackTrace: st,
      );
      _emitState(const SessionUnauthenticated());
    }
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Persists tokens and transitions to [SessionAuthenticated].
  ///
  /// [accessToken] and [refreshToken] are written to [TokenStore].
  /// The `sub` (subject) claim from [accessToken] is used as [userId] when
  /// [userId] is not provided. [userData] is optional supplementary profile
  /// data.
  ///
  /// Throws [AuthException] when the user ID cannot be resolved or storage
  /// fails.
  Future<void> login({
    required String accessToken,
    required String refreshToken,
    String? userId,
    Map<String, dynamic>? userData,
  }) async {
    try {
      await Future.wait([
        _tokenStore.saveAccessToken(accessToken),
        _tokenStore.saveRefreshToken(refreshToken),
      ]);

      final resolvedUserId =
          userId ?? _extractSubject(accessToken) ?? _fallbackUserId();

      await _securePrefs.setString(_keyUserId, resolvedUserId);
      if (userData != null) {
        await _securePrefs.setJson(_keyUserData, userData);
      }

      _emitState(
        SessionAuthenticated(userId: resolvedUserId, userData: userData),
      );

      PrimekitLogger.info(
        'User logged in: $resolvedUserId',
        tag: 'SessionManager',
      );
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Login failed',
        tag: 'SessionManager',
        error: e,
        stackTrace: st,
      );
      throw AuthException(
        message: 'Failed to establish session',
        code: 'LOGIN_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Clears all tokens, removes persisted session data, and transitions to
  /// [SessionUnauthenticated].
  ///
  /// Safe to call even when already unauthenticated.
  Future<void> logout() async {
    try {
      await Future.wait([
        _tokenStore.clearAll(),
        _securePrefs.remove(_keyUserId),
        _securePrefs.remove(_keyUserData),
      ]);
      _emitState(const SessionUnauthenticated());
      PrimekitLogger.info('User logged out', tag: 'SessionManager');
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Logout encountered an error; forcing unauthenticated state',
        tag: 'SessionManager',
        error: e,
        stackTrace: st,
      );
      // Even on failure, transition to unauthenticated to avoid a stuck state.
      _emitState(const SessionUnauthenticated());
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emitState(SessionState next) {
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
    notifyListeners();
  }

  /// Attempts to extract the `sub` claim from a JWT access token.
  ///
  /// Returns `null` on any decode error.
  String? _extractSubject(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final sub = payload['sub'];
      return sub is String ? sub : null;
    } on Exception {
      return null;
    }
  }

  String _fallbackUserId() =>
      'user_${DateTime.now().millisecondsSinceEpoch}';

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}
