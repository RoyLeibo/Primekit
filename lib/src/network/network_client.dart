import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'api_response.dart';
import 'retry_interceptor.dart';

/// A pre-configured [Dio] HTTP client for Primekit-powered applications.
///
/// [PrimekitNetworkClient] wraps [Dio] with:
/// - [RetryInterceptor] for automatic exponential-backoff retries on 5xx / network errors.
/// - A structured logging interceptor that records every request/response.
/// - An optional auth-interceptor slot — supply `onAuthToken` to inject a
///   bearer token on every request.
/// - Consistent [ApiResponse] return types so callers never deal with raw
///   [DioException]s.
///
/// ```dart
/// final client = PrimekitNetworkClient(
///   baseUrl: 'https://api.example.com',
///   headers: {'X-App-Version': '1.0.0'},
///   onAuthToken: () async =>
///       await SecureStorage.instance.read('access_token'),
/// );
///
/// final response = await client.get<User>(
///   '/users/me',
///   parser: (json) => User.fromJson(json as Map<String, dynamic>),
/// );
///
/// response.when(
///   loading: () {},  // never returned by these methods
///   success: (user) => print(user.name),
///   failure: (err)  => print(err.userMessage),
/// );
/// ```
final class PrimekitNetworkClient {
  /// Creates a [PrimekitNetworkClient].
  ///
  /// [baseUrl] is required. [headers] are merged with the default headers
  /// (`Accept: application/json`, `Content-Type: application/json`).
  /// [timeout] applies to both connection and receive operations (default 30s).
  /// [onAuthToken] is an optional async callback that returns the current
  /// bearer token; it is called before each request.
  PrimekitNetworkClient({
    required String baseUrl,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 30),
    Future<String?> Function()? onAuthToken,
    int maxRetries = 3,
    Duration retryInitialDelay = const Duration(seconds: 1),
  }) : _onAuthToken = onAuthToken,
       _dio = _buildDio(
         baseUrl: baseUrl,
         headers: headers,
         timeout: timeout,
         maxRetries: maxRetries,
         retryInitialDelay: retryInitialDelay,
       );

  static const String _tag = 'PrimekitNetworkClient';

  final Dio _dio;
  final Future<String?> Function()? _onAuthToken;

  // ---------------------------------------------------------------------------
  // HTTP methods
  // ---------------------------------------------------------------------------

  /// Performs a GET request to [path].
  ///
  /// [queryParameters] are appended to the URL. [parser] converts the raw
  /// response body to [T]; if omitted the raw `dynamic` value is returned.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    final authHeaders = await _authHeader();
    return _execute<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: authHeaders),
      ),
      parser: parser,
    );
  }

  /// Performs a POST request to [path] with optional [body].
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    final authHeaders = await _authHeader();
    return _execute<T>(
      () => _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: authHeaders),
      ),
      parser: parser,
    );
  }

  /// Performs a PUT request to [path] with optional [body].
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    final authHeaders = await _authHeader();
    return _execute<T>(
      () => _dio.put<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: authHeaders),
      ),
      parser: parser,
    );
  }

  /// Performs a PATCH request to [path] with optional [body].
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    final authHeaders = await _authHeader();
    return _execute<T>(
      () => _dio.patch<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: authHeaders),
      ),
      parser: parser,
    );
  }

  /// Performs a DELETE request to [path].
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    final authHeaders = await _authHeader();
    return _execute<T>(
      () => _dio.delete<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: authHeaders),
      ),
      parser: parser,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<dynamic>> Function() call, {
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await call();
      final data = response.data;

      if (parser != null) {
        return ApiResponse.success(parser(data));
      }

      // Without a parser, we try a direct cast.  If T is dynamic this always
      // succeeds; if T is a concrete type and the response body doesn't match,
      // the cast will throw and be caught below.
      return ApiResponse.success(data as T);
    } on DioException catch (e, stack) {
      final pkError = _mapDioError(e);
      PrimekitLogger.error(
        'HTTP error: ${e.message}',
        tag: _tag,
        error: pkError,
        stackTrace: stack,
      );
      return ApiResponse.failure(pkError);
    } on Exception catch (e, stack) {
      final pkError = NetworkException(
        message: 'Unexpected error: $e',
        cause: e,
      );
      PrimekitLogger.error(
        'Unexpected network error.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ApiResponse.failure(pkError);
    }
  }

  Future<Map<String, String>?> _authHeader() async {
    final token = await _onAuthToken?.call();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  static PrimekitException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return TimeoutException(
        message: 'Request timed out: ${error.requestOptions.path}',
        cause: error,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.response == null) {
      return const NoConnectivityException();
    }

    if (statusCode == 401) {
      return const TokenExpiredException();
    }

    if (statusCode == 403) {
      return UnauthorizedException(
        message: 'Access denied: ${error.requestOptions.path}',
      );
    }

    return NetworkException(
      message: error.message ?? 'HTTP error',
      statusCode: statusCode,
      cause: error,
    );
  }

  // ---------------------------------------------------------------------------
  // Dio factory
  // ---------------------------------------------------------------------------

  static Dio _buildDio({
    required String baseUrl,
    required Map<String, String> headers,
    required Duration timeout,
    required int maxRetries,
    required Duration retryInitialDelay,
  }) {
    final defaultHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...headers,
    };

    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: defaultHeaders,
    );

    final dio = Dio(options);

    // Retry interceptor — must be first so it wraps the log interceptor.
    dio.interceptors.add(
      RetryInterceptor(maxRetries: maxRetries, initialDelay: retryInitialDelay),
    );

    // Logging interceptor — only active in debug builds.
    if (kDebugMode) {
      dio.interceptors.add(_PrimekitLogInterceptor());
    }

    return dio;
  }
}

// ---------------------------------------------------------------------------
// Internal logging interceptor
// ---------------------------------------------------------------------------

/// Lightweight Dio interceptor that routes request/response logs through
/// [PrimekitLogger] rather than [print].
final class _PrimekitLogInterceptor extends Interceptor {
  static const String _tag = 'HTTP';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    PrimekitLogger.debug(
      '→ ${options.method} ${options.baseUrl}${options.path}',
      tag: _tag,
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    PrimekitLogger.debug(
      '← ${response.statusCode} '
      '${response.requestOptions.method} '
      '${response.requestOptions.path}',
      tag: _tag,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    PrimekitLogger.warning(
      '✗ ${err.requestOptions.method} ${err.requestOptions.path}: '
      '${err.message}',
      tag: _tag,
      error: err,
    );
    handler.next(err);
  }
}
