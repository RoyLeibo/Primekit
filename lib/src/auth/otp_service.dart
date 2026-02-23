import 'dart:math';

import '../core/logger.dart';

// ---------------------------------------------------------------------------
// Value types
// ---------------------------------------------------------------------------

/// A stored OTP entry with code, expiry, and attempt tracking.
final class OtpEntry {
  const OtpEntry({
    required this.code,
    required this.expiresAt,
    this.attempts = 0,
  });

  /// The generated OTP code.
  final String code;

  /// UTC timestamp after which this OTP is invalid.
  final DateTime expiresAt;

  /// Number of failed validation attempts made against this entry.
  final int attempts;

  /// Returns a copy with [attempts] incremented by one.
  OtpEntry incrementAttempts() =>
      OtpEntry(code: code, expiresAt: expiresAt, attempts: attempts + 1);

  /// Whether this entry has passed its [expiresAt] threshold.
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  @override
  String toString() => 'OtpEntry(expiresAt: $expiresAt, attempts: $attempts)';
}

/// The outcome of an [OtpService.validate] call.
enum OtpValidationResult {
  /// The code matched and was not expired.
  valid,

  /// The entry's TTL has passed.
  expired,

  /// The code did not match.
  invalid,

  /// The maximum number of allowed attempts was reached.
  maxAttemptsReached,

  /// No OTP was found for the given key.
  notFound,
}

// ---------------------------------------------------------------------------
// OtpService
// ---------------------------------------------------------------------------

/// Generates and validates time-limited one-time passwords (OTPs) for
/// email/SMS authentication flows.
///
/// OTPs are stored **in-memory only** — they are not persisted across restarts,
/// which is intentional: OTPs should be short-lived and re-sent on app
/// restart. Use server-side storage when cross-process persistence is required.
///
/// ```dart
/// final service = OtpService.instance;
///
/// // Generate & store
/// final code = service.generate();
/// service.store('user@example.com', code, ttl: Duration(minutes: 5));
///
/// // Validate on user input
/// final result = service.validate('user@example.com', userInput);
/// if (result == OtpValidationResult.valid) { ... }
/// ```
final class OtpService {
  OtpService._internal();

  static final OtpService _instance = OtpService._internal();

  /// The singleton instance.
  static OtpService get instance => _instance;

  /// Maximum failed attempts before the entry is locked out.
  static const int maxAttempts = 5;

  static const String _numericChars = '0123456789';
  static const String _alphanumericChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  final Map<String, OtpEntry> _store = {};
  final Random _random = Random.secure();

  // ---------------------------------------------------------------------------
  // Generate
  // ---------------------------------------------------------------------------

  /// Generates a random OTP code.
  ///
  /// [length] controls the number of characters (default: 6).
  /// When [numeric] is `true` (default), the code contains only digits.
  /// When `false`, it contains mixed-case letters and digits.
  String generate({int length = 6, bool numeric = true}) {
    assert(length > 0, 'OTP length must be positive');
    final chars = numeric ? _numericChars : _alphanumericChars;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    final code = buffer.toString();
    PrimekitLogger.debug('OTP generated (length: $length)', tag: 'OtpService');
    return code;
  }

  // ---------------------------------------------------------------------------
  // Store
  // ---------------------------------------------------------------------------

  /// Stores [otp] under [key] with the given time-to-live [ttl].
  ///
  /// Any previous entry for [key] is overwritten. [ttl] defaults to 10
  /// minutes, matching common email/SMS OTP lifetimes.
  void store(
    String key,
    String otp, {
    Duration ttl = const Duration(minutes: 10),
  }) {
    assert(key.isNotEmpty, 'OTP key must not be empty');
    assert(otp.isNotEmpty, 'OTP code must not be empty');

    final entry = OtpEntry(
      code: otp,
      expiresAt: DateTime.now().toUtc().add(ttl),
    );
    _store[key] = entry;
    PrimekitLogger.debug(
      'OTP stored for key "$key", expires at ${entry.expiresAt.toIso8601String()}',
      tag: 'OtpService',
    );
  }

  // ---------------------------------------------------------------------------
  // Validate
  // ---------------------------------------------------------------------------

  /// Validates [code] against the OTP stored under [key].
  ///
  /// Returns one of:
  /// - [OtpValidationResult.notFound] — no entry for [key].
  /// - [OtpValidationResult.expired] — entry exists but TTL has passed.
  /// - [OtpValidationResult.maxAttemptsReached] — entry locked after too
  ///   many failures.
  /// - [OtpValidationResult.valid] — code matched; entry is removed.
  /// - [OtpValidationResult.invalid] — code did not match; attempt recorded.
  OtpValidationResult validate(String key, String code) {
    final entry = _store[key];

    if (entry == null) {
      PrimekitLogger.debug(
        'OTP validation: no entry for key "$key"',
        tag: 'OtpService',
      );
      return OtpValidationResult.notFound;
    }

    if (entry.isExpired) {
      _store.remove(key);
      PrimekitLogger.debug(
        'OTP validation: entry expired for key "$key"',
        tag: 'OtpService',
      );
      return OtpValidationResult.expired;
    }

    if (entry.attempts >= maxAttempts) {
      PrimekitLogger.warning(
        'OTP validation: max attempts reached for key "$key"',
        tag: 'OtpService',
      );
      return OtpValidationResult.maxAttemptsReached;
    }

    if (_constantTimeEquals(entry.code, code)) {
      _store.remove(key);
      PrimekitLogger.info(
        'OTP validation: success for key "$key"',
        tag: 'OtpService',
      );
      return OtpValidationResult.valid;
    }

    // Record failed attempt.
    _store[key] = entry.incrementAttempts();
    PrimekitLogger.debug(
      'OTP validation: invalid code for key "$key" '
      '(attempt ${_store[key]!.attempts}/$maxAttempts)',
      tag: 'OtpService',
    );
    return OtpValidationResult.invalid;
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  /// Removes the OTP entry for [key], if any.
  void clear(String key) {
    _store.remove(key);
    PrimekitLogger.debug('OTP entry cleared for key "$key"', tag: 'OtpService');
  }

  /// Removes all stored OTP entries.
  ///
  /// Useful in test tear-downs or on sign-out.
  void clearAll() {
    _store.clear();
    PrimekitLogger.debug('All OTP entries cleared', tag: 'OtpService');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Compares two strings in constant time to prevent timing attacks.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
