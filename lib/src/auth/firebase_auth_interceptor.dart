import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core.dart';

/// A Dio [Interceptor] for apps that use Firebase Authentication.
///
/// Attaches a fresh Firebase ID token as a `Bearer` token on every outgoing
/// request. On a `401 Unauthorized` response it force-refreshes the token and
/// retries the original request exactly once. If the current user is signed
/// out, or the refresh fails, it calls [onSessionExpired].
///
/// Unlike [AuthInterceptor] (JWT access/refresh), no token store is needed —
/// Firebase manages its own token lifecycle and refresh internally.
///
/// Usage:
/// ```dart
/// dio.interceptors.add(
///   FirebaseAuthInterceptor(
///     onSessionExpired: () => router.go('/login'),
///   ),
/// );
/// ```
class FirebaseAuthInterceptor extends Interceptor {
  FirebaseAuthInterceptor({
    VoidCallback? onSessionExpired,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _onSessionExpired = onSessionExpired;

  final FirebaseAuth _auth;
  final VoidCallback? _onSessionExpired;

  static const String _tag = 'FirebaseAuthInterceptor';
  static const String _retriedKey = '_firebaseAuthRetried';

  // ---------------------------------------------------------------------------
  // Request: attach ID token
  // ---------------------------------------------------------------------------

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _getIdToken(forceRefresh: false);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        PrimekitLogger.verbose(
          'Attached Firebase ID token to ${options.method} ${options.path}',
          tag: _tag,
        );
      }
    } catch (e) {
      PrimekitLogger.warning(
        'Failed to attach Firebase ID token',
        tag: _tag,
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
  ) =>
      handler.next(response);

  // ---------------------------------------------------------------------------
  // Error: handle 401 with force-refresh + retry
  // ---------------------------------------------------------------------------

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Prevent retry loop: if this request already carried the retried flag, bail.
    if (err.requestOptions.extra[_retriedKey] == true) {
      PrimekitLogger.warning(
        'Firebase token refresh loop detected — expiring session',
        tag: _tag,
      );
      _onSessionExpired?.call();
      handler.next(err);
      return;
    }

    PrimekitLogger.info(
      '401 on ${err.requestOptions.path} — force-refreshing Firebase ID token',
      tag: _tag,
    );

    final freshToken = await _getIdToken(forceRefresh: true);

    if (freshToken == null) {
      PrimekitLogger.warning(
        'No authenticated Firebase user — expiring session',
        tag: _tag,
      );
      _onSessionExpired?.call();
      handler.next(err);
      return;
    }

    try {
      final requestOptions = err.requestOptions;

      final retryOptions = Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $freshToken',
        },
        extra: {...requestOptions.extra, _retriedKey: true},
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        validateStatus: requestOptions.validateStatus,
      );

      final uri = requestOptions.uri;
      final port = uri.port;
      final isDefaultPort = port == 80 || port == 443 || port == -1;
      final baseUrl =
          '${uri.scheme}://${uri.host}${isDefaultPort ? '' : ':$port'}';
      final retryDio = Dio(BaseOptions(baseUrl: baseUrl));

      final retryResponse = await retryDio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: retryOptions,
      );

      PrimekitLogger.info(
        'Retry succeeded after Firebase token refresh',
        tag: _tag,
      );
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      PrimekitLogger.error(
        'Retry failed after Firebase token refresh',
        tag: _tag,
        error: retryErr,
      );
      if (retryErr.response?.statusCode == 401) {
        _onSessionExpired?.call();
      }
      handler.next(retryErr);
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Unexpected error during Firebase auth retry',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      handler.next(err);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String?> _getIdToken({required bool forceRefresh}) async {
    try {
      // On web, Firebase restores auth state from IndexedDB asynchronously.
      // currentUser is null until that completes. Wait for authStateChanges
      // to emit so the first request on a restored session is authenticated.
      var user = _auth.currentUser;
      user ??= await _auth.authStateChanges().first;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (e, st) {
      PrimekitLogger.error(
        'getIdToken(forceRefresh: $forceRefresh) failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
