import '../core/exceptions.dart';

// ---------------------------------------------------------------------------
// Concrete state types
// ---------------------------------------------------------------------------

/// Represents a loading / in-flight request.
final class ApiLoading<T> implements ApiResponse<T> {
  const ApiLoading();

  @override
  bool get isLoading => true;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => false;

  @override
  T? get dataOrNull => null;

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(PrimekitException error) failure,
  }) =>
      loading();

  @override
  ApiResponse<R> map<R>(R Function(T data) transform) => ApiLoading<R>();

  @override
  String toString() => 'ApiResponse.loading()';
}

/// Represents a successfully completed request.
final class ApiSuccess<T> implements ApiResponse<T> {
  const ApiSuccess(this.data);

  /// The response payload.
  final T data;

  @override
  bool get isLoading => false;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T? get dataOrNull => data;

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(PrimekitException error) failure,
  }) =>
      success(data);

  @override
  ApiResponse<R> map<R>(R Function(T data) transform) =>
      ApiSuccess<R>(transform(data));

  @override
  String toString() => 'ApiResponse.success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiSuccess<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Represents a failed request.
final class ApiFailure<T> implements ApiResponse<T> {
  const ApiFailure(this.error);

  /// The error that caused the failure.
  final PrimekitException error;

  @override
  bool get isLoading => false;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get dataOrNull => null;

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(PrimekitException error) failure,
  }) =>
      failure(error);

  @override
  ApiResponse<R> map<R>(R Function(T data) transform) => ApiFailure<R>(error);

  @override
  String toString() => 'ApiResponse.failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiFailure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

// ---------------------------------------------------------------------------
// Sealed union
// ---------------------------------------------------------------------------

/// A discriminated union modelling the three states of an asynchronous API
/// call: loading, success, and failure.
///
/// Construct via the factory constructors:
///
/// ```dart
/// ApiResponse<User> state = const ApiResponse.loading();
/// state = ApiResponse.success(user);
/// state = ApiResponse.failure(NetworkException(message: 'Timeout'));
/// ```
///
/// Exhaustively handle states with [when]:
///
/// ```dart
/// final widget = response.when(
///   loading: () => const CircularProgressIndicator(),
///   success: (user) => UserCard(user: user),
///   failure: (error) => ErrorView(message: error.userMessage),
/// );
/// ```
sealed class ApiResponse<T> {

  /// Creates a loading state.
  const factory ApiResponse.loading() = ApiLoading<T>;

  /// Creates a success state with [data] as the payload.
  const factory ApiResponse.success(T data) = ApiSuccess<T>;

  /// Creates a failure state with [error] describing what went wrong.
  const factory ApiResponse.failure(PrimekitException error) = ApiFailure<T>;

  // ---------------------------------------------------------------------------
  // State predicates
  // ---------------------------------------------------------------------------

  /// Returns `true` while the request is in-flight.
  bool get isLoading;

  /// Returns `true` when the request succeeded.
  bool get isSuccess;

  /// Returns `true` when the request failed.
  bool get isFailure;

  // ---------------------------------------------------------------------------
  // Data access
  // ---------------------------------------------------------------------------

  /// Returns the response data, or `null` when not in the success state.
  T? get dataOrNull;

  // ---------------------------------------------------------------------------
  // Pattern matching
  // ---------------------------------------------------------------------------

  /// Exhaustively maps each state to a value of type [R].
  ///
  /// All three branches are required; the compiler enforces exhaustiveness.
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(PrimekitException error) failure,
  });

  // ---------------------------------------------------------------------------
  // Transformation
  // ---------------------------------------------------------------------------

  /// Applies [transform] to the success payload, producing an [ApiResponse]
  /// of the new type [R].
  ///
  /// Loading and failure states pass through unchanged with their type updated.
  ApiResponse<R> map<R>(R Function(T data) transform);
}
