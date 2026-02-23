import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../core/logger.dart';

/// A Dio [Interceptor] that automatically retries failed requests with
/// exponential backoff.
///
/// Retry behaviour:
/// - Retries on network errors (no response received) and 5xx server errors.
/// - Does **not** retry on 4xx client errors — these indicate a problem with
///   the request itself that a retry cannot fix.
/// - Each retry waits `initialDelay * 2^(attempt - 1)` before executing,
///   capped at [maxDelay].
/// - After [maxRetries] failed attempts the original error is rethrown.
///
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(
///   RetryInterceptor(
///     maxRetries: 3,
///     initialDelay: const Duration(seconds: 1),
///   ),
/// );
/// ```
final class RetryInterceptor extends Interceptor {
  /// Creates a [RetryInterceptor].
  ///
  /// [maxRetries] controls how many additional attempts are made after the
  /// initial failure (default 3). [initialDelay] is the wait before the first
  /// retry; subsequent retries double this delay (default 1 second).
  /// [maxDelay] caps the backoff (default 30 seconds).
  const RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Delay before the first retry. Doubles with each subsequent attempt.
  final Duration initialDelay;

  /// Upper bound on the computed backoff delay.
  final Duration maxDelay;

  static const String _tag = 'RetryInterceptor';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    final attempt = _attemptCount(requestOptions);

    if (attempt >= maxRetries) {
      PrimekitLogger.warning(
        'Retry budget exhausted after $maxRetries attempt(s): '
        '${requestOptions.method} ${requestOptions.path}',
        tag: _tag,
      );
      handler.next(err);
      return;
    }

    final delay = _backoffDelay(attempt);
    final nextAttempt = attempt + 1;

    PrimekitLogger.info(
      'Retrying (attempt $nextAttempt/$maxRetries) in ${delay.inMilliseconds}ms: '
      '${requestOptions.method} ${requestOptions.path}',
      tag: _tag,
    );

    await Future<void>.delayed(delay);

    // Tag the extra map with the updated attempt count (immutable copy).
    final updatedExtra = Map<String, Object?>.unmodifiable({
      ...requestOptions.extra,
      _attemptKey: nextAttempt,
    });

    final retryOptions = requestOptions.copyWith(extra: updatedExtra);

    try {
      // Re-execute the request using the same Dio instance stored in the
      // request options.
      final dio = Dio(
        BaseOptions(
          baseUrl: requestOptions.baseUrl,
          connectTimeout: requestOptions.connectTimeout,
          receiveTimeout: requestOptions.receiveTimeout,
          sendTimeout: requestOptions.sendTimeout,
          headers: Map<String, Object?>.unmodifiable(
            requestOptions.headers.cast<String, Object?>(),
          ),
          responseType: requestOptions.responseType,
          contentType: requestOptions.contentType,
        ),
      );

      final response = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      // Recursively trigger onError so further retries are attempted.
      await onError(retryError, handler);
    } on Exception catch (error) {
      handler.next(DioException(requestOptions: requestOptions, error: error));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static const String _attemptKey = '_primekit_retry_attempt';

  bool _shouldRetry(DioException err) {
    // Network errors (no response) — always safe to retry.
    if (err.response == null) return true;

    final statusCode = err.response?.statusCode ?? 0;

    // 5xx — server-side error, retry may succeed once the server recovers.
    if (statusCode >= 500 && statusCode < 600) return true;

    // 4xx — client error; retrying the same request will always fail.
    return false;
  }

  int _attemptCount(RequestOptions options) =>
      (options.extra[_attemptKey] as int?) ?? 0;

  Duration _backoffDelay(int attempt) {
    final multiplier = math.pow(2, attempt).toInt();
    final computed = Duration(
      milliseconds: initialDelay.inMilliseconds * multiplier,
    );
    return computed > maxDelay ? maxDelay : computed;
  }
}
