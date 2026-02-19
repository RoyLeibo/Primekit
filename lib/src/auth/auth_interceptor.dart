import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'token_store.dart' show TokenStoreBase;

/// A callback that receives the current refresh token and must return a fresh
/// access token on success, or `null` on failure.
typedef TokenRefreshCallback = Future<String?> Function(String refreshToken);

/// A Dio [Interceptor] that handles JWT-based authentication transparently.
///
/// Responsibilities:
/// 1. Attaches the stored `Bearer` access token to every outgoing request.
/// 2. On a `401 Unauthorized` response, attempts a token refresh via
///    [onRefresh].
/// 3. On a successful refresh, saves the new access token and retries the
///    original request exactly once.
/// 4. On a failed refresh (no refresh token available, or [onRefresh] returns
///    `null`), clears all stored tokens and invokes [onSessionExpired] so the
///    app can navigate to the login screen.
///
/// Only one concurrent refresh is performed at a time — parallel 401 responses
/// all wait for the single in-flight refresh before deciding whether to retry.
///
/// Usage:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(
///   AuthInterceptor(
///     tokenStore: TokenStore.instance,
///     onRefresh: (refreshToken) async {
///       final response = await authApi.refresh(refreshToken);
///       return response.accessToken;
///     },
///     onSessionExpired: () => router.go('/login'),
///   ),
/// );
/// ```
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStoreBase tokenStore,
    required TokenRefreshCallback onRefresh,
    required VoidCallback onSessionExpired,
  })  : _tokenStore = tokenStore,
        _onRefresh = onRefresh,
        _onSessionExpired = onSessionExpired;

  final TokenStoreBase _tokenStore;
  final TokenRefreshCallback _onRefresh;
  final VoidCallback _onSessionExpired;

  /// Completer guarding a single in-flight refresh; `null` when idle.
  Completer<String?>? _refreshCompleter;

  // ---------------------------------------------------------------------------
  // Request: attach Bearer token
  // ---------------------------------------------------------------------------

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenStore.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        PrimekitLogger.verbose(
          'Attached Bearer token to ${options.method} ${options.path}',
          tag: 'AuthInterceptor',
        );
      }
    } catch (e) {
      PrimekitLogger.warning(
        'Could not read access token for request',
        tag: 'AuthInterceptor',
        error: e,
      );
    }
    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // Response: pass through
  // ---------------------------------------------------------------------------

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  // ---------------------------------------------------------------------------
  // Error: handle 401 with token refresh + retry
  // ---------------------------------------------------------------------------

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    // Only handle 401 responses. Pass everything else through.
    if (statusCode != 401) {
      handler.next(err);
      return;
    }

    // Prevent an infinite retry loop: if this request already carried a
    // retried flag, bail out immediately.
    if (requestOptions.extra['_authRetried'] == true) {
      PrimekitLogger.warning(
        'Token refresh loop detected — expiring session',
        tag: 'AuthInterceptor',
      );
      await _expireSession();
      handler.next(err);
      return;
    }

    PrimekitLogger.info(
      '401 received for ${requestOptions.path} — attempting token refresh',
      tag: 'AuthInterceptor',
    );

    final newAccessToken = await _refreshAccessToken();

    if (newAccessToken == null) {
      PrimekitLogger.warning(
        'Token refresh failed — expiring session',
        tag: 'AuthInterceptor',
      );
      await _expireSession();
      handler.next(err);
      return;
    }

    // Retry the original request with the fresh token.
    try {
      final retryOptions = Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $newAccessToken',
        },
        extra: {
          ...requestOptions.extra,
          '_authRetried': true,
        },
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        validateStatus: requestOptions.validateStatus,
      );

      // Build a minimal Dio instance without this interceptor to avoid
      // re-entry; reuse the base URL from the original request URI.
      final uri = requestOptions.uri;
      final baseUrl = '${uri.scheme}://${uri.host}'
          '${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final retryDio = Dio(BaseOptions(baseUrl: baseUrl));

      final retryResponse = await retryDio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: retryOptions,
      );

      PrimekitLogger.info(
        'Retry succeeded for ${requestOptions.path}',
        tag: 'AuthInterceptor',
      );
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      PrimekitLogger.error(
        'Retry request failed after token refresh',
        tag: 'AuthInterceptor',
        error: retryErr,
      );
      if (retryErr.response?.statusCode == 401) {
        await _expireSession();
      }
      handler.next(retryErr);
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Unexpected error during retry',
        tag: 'AuthInterceptor',
        error: e,
        stackTrace: st,
      );
      handler.next(err);
    }
  }

  // ---------------------------------------------------------------------------
  // Token refresh (serialised with a Completer)
  // ---------------------------------------------------------------------------

  /// Performs or awaits an in-flight token refresh.
  ///
  /// Returns the new access token, or `null` on failure.
  Future<String?> _refreshAccessToken() async {
    // If a refresh is already running, wait for it to complete.
    if (_refreshCompleter != null) {
      PrimekitLogger.verbose(
        'Waiting for in-flight token refresh',
        tag: 'AuthInterceptor',
      );
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenStore.getRefreshToken();
      if (refreshToken == null) {
        PrimekitLogger.warning(
          'No refresh token available',
          tag: 'AuthInterceptor',
        );
        _refreshCompleter!.complete(null);
        return null;
      }

      final newAccessToken = await _onRefresh(refreshToken);

      if (newAccessToken != null) {
        await _tokenStore.saveAccessToken(newAccessToken);
        PrimekitLogger.info(
          'Token refreshed successfully',
          tag: 'AuthInterceptor',
        );
      }

      _refreshCompleter!.complete(newAccessToken);
      return newAccessToken;
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Token refresh callback threw',
        tag: 'AuthInterceptor',
        error: e,
        stackTrace: st,
      );
      _refreshCompleter!.completeError(e, st);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Session expiry
  // ---------------------------------------------------------------------------

  Future<void> _expireSession() async {
    try {
      await _tokenStore.clearAll();
    } on Exception catch (e) {
      PrimekitLogger.warning(
        'Could not clear tokens during session expiry',
        tag: 'AuthInterceptor',
        error: e,
      );
    }
    try {
      _onSessionExpired();
    } on Exception catch (e) {
      PrimekitLogger.error(
        'onSessionExpired callback threw',
        tag: 'AuthInterceptor',
        error: e,
      );
      throw AuthException(
        message: 'Session expired callback failed',
        code: 'SESSION_EXPIRED_CALLBACK_FAILED',
        cause: e,
      );
    }
  }
}
