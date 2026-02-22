import 'exceptions.dart';

/// A discriminated union representing either a successful value [S]
/// or a failure [F].
///
/// Inspired by Rust's `Result<T, E>` and fp-ts's `Either`.
///
/// ```dart
/// final result = await fetchUser();
/// result.when(
///   success: (user) => print('Got user: ${user.name}'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
sealed class Result<S, F> {
  const Result();

  /// Creates a successful result containing [value].
  const factory Result.success(S value) = Success<S, F>;

  /// Creates a failure result containing [failure].
  const factory Result.failure(F failure) = Failure<S, F>;

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<S, F>;

  /// Returns `true` if this is a [Failure].
  bool get isFailure => this is Failure<S, F>;

  /// Returns the success value, or `null` if this is a failure.
  S? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// Returns the failure value, or `null` if this is a success.
  F? get failureOrNull => switch (this) {
        Success() => null,
        Failure(:final failure) => failure,
      };

  /// Returns the success value or throws a [StateError].
  S get valueOrThrow => switch (this) {
        Success(:final value) => value,
        Failure(:final failure) =>
          throw StateError('Called valueOrThrow on a Failure: $failure'),
      };

  /// Executes [success] or [failure] depending on the variant.
  T when<T>({
    required T Function(S value) success,
    required T Function(F failure) failure,
  }) =>
      switch (this) {
        Success(:final value) => success(value),
        Failure(failure: final f) => failure(f),
      };

  /// Maps the success value using [transform], leaving failures unchanged.
  Result<T, F> map<T>(T Function(S value) transform) => switch (this) {
        Success(:final value) => Result.success(transform(value)),
        Failure(:final failure) => Result.failure(failure),
      };

  /// Maps the failure value using [transform], leaving successes unchanged.
  Result<S, T> mapFailure<T>(T Function(F failure) transform) => switch (this) {
        Success(:final value) => Result.success(value),
        Failure(:final failure) => Result.failure(transform(failure)),
      };

  /// Flat-maps the success value, used for chaining operations.
  Future<Result<T, F>> asyncMap<T>(
    Future<Result<T, F>> Function(S value) transform,
  ) =>
      switch (this) {
        Success(:final value) => transform(value),
        Failure(:final failure) => Future.value(Result.failure(failure)),
      };

  /// Returns [other] if this is a failure, otherwise returns this.
  Result<S, F> or(Result<S, F> other) => isSuccess ? this : other;

  @override
  String toString() => switch (this) {
        Success(:final value) => 'Result.success($value)',
        Failure(:final failure) => 'Result.failure($failure)',
      };
}

/// The success variant of [Result].
final class Success<S, F> extends Result<S, F> {
  /// Creates a successful result.
  const Success(this.value);

  /// The contained success value.
  final S value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<S, F> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// The failure variant of [Result].
final class Failure<S, F> extends Result<S, F> {
  /// Creates a failure result.
  const Failure(this.failure);

  /// The contained failure value.
  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<S, F> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}

/// Convenience typedef for results that fail with a [PrimekitException].
typedef PkResult<T> = Result<T, PrimekitException>;
