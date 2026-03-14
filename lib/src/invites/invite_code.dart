import 'dart:math';

/// Utility class for generating and validating invite codes.
///
/// All apps use 6-digit numeric codes.
///
/// ```dart
/// final code = InviteCode.generateCode(); // "482917"
/// InviteCode.isValidCode('123456'); // true
/// InviteCode.isExpired(createdAt); // false (within 7 days)
/// ```
class InviteCode {
  InviteCode._();

  static final _random = Random.secure();

  /// Default expiration for invite codes (7 days).
  static const defaultExpiration = Duration(days: 7);

  /// Generates a random 6-digit numeric invite code.
  static String generateCode() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
  }

  /// Returns `true` if [code] is exactly 6 digits.
  static bool isValidCode(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  /// Characters used for link generation.
  ///
  /// Excludes ambiguous characters (0, O, I, l) to avoid confusion.
  static const _linkChars = 'abcdefghjkmnpqrstuvwxyz123456789';

  /// Generates a random 8-character alphanumeric invite link identifier.
  ///
  /// Uses lowercase letters and digits, excluding ambiguous characters
  /// (0, O, I, l) to avoid confusion.
  static String generateLink() {
    return List.generate(
      8,
      (_) => _linkChars[_random.nextInt(_linkChars.length)],
    ).join();
  }

  /// Returns `true` if [link] is exactly 8 lowercase alphanumeric characters.
  static bool isValidLink(String link) {
    return RegExp(r'^[a-hjkmnp-z1-9]{8}$').hasMatch(link);
  }

  /// Returns `true` if a code created at [createdAt] has expired.
  ///
  /// Uses [expiration] duration (defaults to 7 days).
  static bool isExpired(
    DateTime createdAt, {
    Duration expiration = defaultExpiration,
  }) {
    return DateTime.now().isAfter(createdAt.add(expiration));
  }
}
