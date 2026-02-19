/// Base exception class for all Primekit errors.
///
/// All modules throw subtypes of [PrimekitException], allowing callers
/// to catch all Primekit errors uniformly:
/// ```dart
/// try {
///   await billingService.purchase(product);
/// } on PrimekitException catch (e) {
///   showErrorDialog(e.userMessage);
/// }
/// ```
sealed class PrimekitException implements Exception {
  const PrimekitException({
    required this.message,
    this.code,
    this.cause,
  });

  /// Developer-facing error message.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  /// The underlying exception that caused this error, if any.
  final Object? cause;

  /// A safe, user-facing message (defaults to generic message).
  String get userMessage => 'Something went wrong. Please try again.';

  @override
  String toString() => 'PrimekitException(code: $code, message: $message)';
}

// ---------------------------------------------------------------------------
// Network
// ---------------------------------------------------------------------------

/// Thrown when a network request fails.
final class NetworkException extends PrimekitException {
  const NetworkException({
    required super.message,
    this.statusCode,
    super.code,
    super.cause,
  });

  final int? statusCode;

  @override
  String get userMessage => statusCode == null
      ? 'Network error. Check your connection and try again.'
      : 'Server error ($statusCode). Please try again later.';
}

/// Thrown when the device has no network connectivity.
final class NoConnectivityException extends PrimekitException {
  const NoConnectivityException()
      : super(message: 'No internet connectivity', code: 'NO_CONNECTIVITY');

  @override
  String get userMessage => 'No internet connection. Please check your network.';
}

/// Thrown when a request times out.
final class TimeoutException extends PrimekitException {
  const TimeoutException({required super.message, super.cause})
      : super(code: 'TIMEOUT');

  @override
  String get userMessage => 'Request timed out. Please try again.';
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

/// Thrown for authentication-related failures.
final class AuthException extends PrimekitException {
  const AuthException({required super.message, super.code, super.cause});

  @override
  String get userMessage => 'Authentication failed. Please sign in again.';
}

/// Thrown when an auth token has expired.
final class TokenExpiredException extends AuthException {
  const TokenExpiredException()
      : super(message: 'Auth token has expired', code: 'TOKEN_EXPIRED');

  @override
  String get userMessage => 'Your session has expired. Please sign in again.';
}

/// Thrown when the user is not authorized to access a resource.
final class UnauthorizedException extends AuthException {
  const UnauthorizedException({required super.message})
      : super(code: 'UNAUTHORIZED');

  @override
  String get userMessage => 'You do not have permission to do that.';
}

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

/// Thrown for local storage failures.
final class StorageException extends PrimekitException {
  const StorageException({required super.message, super.code, super.cause});
}

// ---------------------------------------------------------------------------
// Billing
// ---------------------------------------------------------------------------

/// Thrown for billing and in-app purchase failures.
final class BillingException extends PrimekitException {
  const BillingException({required super.message, super.code, super.cause});

  @override
  String get userMessage => 'Purchase failed. Please try again.';
}

/// Thrown when a purchase is cancelled by the user.
final class PurchaseCancelledException extends BillingException {
  const PurchaseCancelledException()
      : super(message: 'Purchase was cancelled', code: 'PURCHASE_CANCELLED');

  @override
  String get userMessage => 'Purchase was cancelled.';
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

/// Thrown when input validation fails.
final class ValidationException extends PrimekitException {
  const ValidationException({
    required super.message,
    required this.errors,
    super.code = 'VALIDATION_FAILED',
  });

  /// Field-level validation errors. Key is field name, value is error message.
  final Map<String, String> errors;

  @override
  String get userMessage => 'Please fix the highlighted fields.';
}

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------

/// Thrown when an email send operation fails.
final class EmailException extends PrimekitException {
  const EmailException({required super.message, super.code, super.cause});

  @override
  String get userMessage => 'Failed to send email. Please try again.';
}

// ---------------------------------------------------------------------------
// Permissions
// ---------------------------------------------------------------------------

/// Thrown when a required permission is denied.
final class PermissionDeniedException extends PrimekitException {
  const PermissionDeniedException({required super.message, super.code});

  @override
  String get userMessage => 'Permission is required to use this feature.';
}

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Thrown when Primekit is misconfigured.
final class ConfigurationException extends PrimekitException {
  const ConfigurationException({required super.message})
      : super(code: 'MISCONFIGURED');
}
