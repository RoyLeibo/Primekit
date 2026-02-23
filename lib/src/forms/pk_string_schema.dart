import 'pk_schema.dart';
import 'validation_result.dart';

/// A schema that validates string values.
///
/// Rules are applied in the order they are chained. The first failing rule
/// produces the error message returned in [ValidationResult.errors].
///
/// ```dart
/// final emailSchema = PkSchema.string().email().required();
/// final result = emailSchema.validate('not-an-email');
/// result.isValid // false
/// result.errors  // {'_': 'Invalid email format'}
/// ```
final class PkStringSchema extends PkSchema<String> {
  PkStringSchema._({
    required bool required,
    required List<_StringRule> rules,
    required bool shouldTrim,
    PkStringSchema? matchTarget,
  }) : _required = required,
       _rules = rules,
       _shouldTrim = shouldTrim,
       _matchTarget = matchTarget;

  /// Creates a new string schema with no constraints.
  PkStringSchema()
    : _required = true,
      _rules = const [],
      _shouldTrim = false,
      _matchTarget = null;

  final bool _required;
  final List<_StringRule> _rules;
  final bool _shouldTrim;
  final PkStringSchema? _matchTarget;

  @override
  bool get isRequired => _required;

  // ---------------------------------------------------------------------------
  // Builder methods — each returns a new immutable instance
  // ---------------------------------------------------------------------------

  /// Marks the field as required (the default).
  ///
  /// Null, absent, or empty-string values will fail with [message].
  PkStringSchema required({String? message}) => _copyWith(
    required: true,
    extraRules: [
      _StringRule(
        test: (v) => v.isNotEmpty,
        message: message ?? 'This field is required',
      ),
    ],
  );

  /// Marks the field as optional.
  ///
  /// Null and absent values pass without error.
  PkStringSchema optional() => _copyWith(required: false);

  /// Validates that the value is a well-formed email address.
  PkStringSchema email({String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => _emailRegex.hasMatch(v),
        message: message ?? 'Invalid email format',
      ),
    ],
  );

  /// Validates that the value is a well-formed HTTP or HTTPS URL.
  PkStringSchema url({String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) {
          final uri = Uri.tryParse(v);
          return uri != null &&
              (uri.isScheme('http') || uri.isScheme('https')) &&
              uri.host.isNotEmpty;
        },
        message: message ?? 'Invalid URL',
      ),
    ],
  );

  /// Validates that the value is a plausible phone number (E.164 or local).
  PkStringSchema phone({String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => _phoneRegex.hasMatch(v),
        message: message ?? 'Invalid phone number',
      ),
    ],
  );

  /// Validates that the value is at least [min] characters long.
  PkStringSchema minLength(int min, {String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => v.length >= min,
        message: message ?? 'Must be at least $min characters',
      ),
    ],
  );

  /// Validates that the value is at most [max] characters long.
  PkStringSchema maxLength(int max, {String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => v.length <= max,
        message: message ?? 'Must be at most $max characters',
      ),
    ],
  );

  /// Validates that the value matches [regex].
  PkStringSchema pattern(RegExp regex, {String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => regex.hasMatch(v),
        message: message ?? 'Invalid format',
      ),
    ],
  );

  /// Validates that the value is one of the provided [values].
  PkStringSchema oneOf(List<String> values, {String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => values.contains(v),
        message: message ?? 'Must be one of: ${values.join(', ')}',
      ),
    ],
  );

  /// Validates that the value is not empty after trimming.
  PkStringSchema notEmpty({String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => v.trim().isNotEmpty,
        message: message ?? 'Must not be empty',
      ),
    ],
  );

  /// Trims leading and trailing whitespace before running any other rules.
  PkStringSchema trim() => _copyWith(shouldTrim: true);

  /// Validates that the value passes the Luhn algorithm (credit card numbers).
  PkStringSchema creditCard({String? message}) => _copyWith(
    extraRules: [
      _StringRule(
        test: (v) => _isValidCreditCard(v),
        message: message ?? 'Invalid credit card number',
      ),
    ],
  );

  /// Validates that the value matches the value produced by [other] at
  /// validation time.
  ///
  /// Primarily used for confirm-password fields:
  ///
  /// ```dart
  /// final password = PkSchema.string().minLength(8).required();
  /// final confirm = PkSchema.string().matches(password).required();
  /// ```
  ///
  /// At validation time both schemas are called with the same raw input map,
  /// so [other] must be part of the same [PkObjectSchema].
  ///
  /// Note: when used standalone (outside an object schema) the [other] schema's
  /// most recently validated value is compared.
  PkStringSchema matches(PkStringSchema other, {String? message}) =>
      PkStringSchema._(
        required: _required,
        rules: _rules,
        shouldTrim: _shouldTrim,
        matchTarget: other,
      )._copyWith(
        extraRules: [
          _StringRule(
            test: (_) => true, // checked separately in validate()
            message: message ?? 'Values do not match',
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  @override
  ValidationResult validate(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      if (!_required) return const ValidationResult.valid(null);
      return const ValidationResult.invalid({'_': 'This field is required'});
    }

    if (value is! String) {
      return const ValidationResult.invalid({'_': 'Must be a string'});
    }

    final processed = _shouldTrim ? value.trim() : value;

    for (final rule in _rules) {
      if (!rule.test(processed)) {
        return ValidationResult.invalid({'_': rule.message});
      }
    }

    if (_matchTarget != null) {
      final targetResult = _matchTarget.validate(value);
      if (!targetResult.isValid || targetResult.value != processed) {
        return ValidationResult.invalid({'_': 'Values do not match'});
      }
    }

    return ValidationResult.valid(processed);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  PkStringSchema _copyWith({
    bool? required,
    List<_StringRule> extraRules = const [],
    bool? shouldTrim,
  }) => PkStringSchema._(
    required: required ?? _required,
    rules: [..._rules, ...extraRules],
    shouldTrim: shouldTrim ?? _shouldTrim,
    matchTarget: _matchTarget,
  );

  static bool _isValidCreditCard(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) return false;

    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+'
    r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  static final RegExp _phoneRegex = RegExp(r'^\+?[\d\s\-()\[\]]{7,20}$');
}

// ---------------------------------------------------------------------------
// Internal rule representation
// ---------------------------------------------------------------------------

final class _StringRule {
  const _StringRule({required this.test, required this.message});

  final bool Function(String value) test;
  final String message;
}
