import 'pk_schema.dart';
import 'validation_result.dart';

/// A schema that validates numeric values (both [int] and [double]).
///
/// ```dart
/// final ageSchema = PkSchema.number().min(0).max(150).integer().required();
/// final result = ageSchema.validate(200);
/// result.isValid // false
/// result.errors  // {'_': 'Must be ≤ 150'}
/// ```
final class PkNumberSchema extends PkSchema<num> {
  PkNumberSchema._({required bool required, required List<_NumberRule> rules})
    : _required = required,
      _rules = rules;

  /// Creates a new number schema with no constraints.
  PkNumberSchema() : _required = true, _rules = const [];

  final bool _required;
  final List<_NumberRule> _rules;

  @override
  bool get isRequired => _required;

  // ---------------------------------------------------------------------------
  // Builder methods
  // ---------------------------------------------------------------------------

  /// Marks the field as required (the default).
  PkNumberSchema required({String? message}) => _copyWith(
    required: true,
    extraRules: [
      _NumberRule(
        test: (_) => true,
        message: message ?? 'This field is required',
      ),
    ],
  );

  /// Marks the field as optional.
  ///
  /// Null and absent values pass without error.
  PkNumberSchema optional() => _copyWith(required: false);

  /// Validates that the value is ≥ [minimum].
  PkNumberSchema min(num minimum, {String? message}) => _copyWith(
    extraRules: [
      _NumberRule(
        test: (v) => v >= minimum,
        message: message ?? 'Must be ≥ $minimum',
      ),
    ],
  );

  /// Validates that the value is ≤ [maximum].
  PkNumberSchema max(num maximum, {String? message}) => _copyWith(
    extraRules: [
      _NumberRule(
        test: (v) => v <= maximum,
        message: message ?? 'Must be ≤ $maximum',
      ),
    ],
  );

  /// Validates that the value is strictly greater than zero.
  PkNumberSchema positive({String? message}) => _copyWith(
    extraRules: [
      _NumberRule(
        test: (v) => v > 0,
        message: message ?? 'Must be a positive number',
      ),
    ],
  );

  /// Validates that the value is strictly less than zero.
  PkNumberSchema negative({String? message}) => _copyWith(
    extraRules: [
      _NumberRule(
        test: (v) => v < 0,
        message: message ?? 'Must be a negative number',
      ),
    ],
  );

  /// Validates that the value has no fractional part.
  PkNumberSchema integer({String? message}) => _copyWith(
    extraRules: [
      _NumberRule(
        test: (v) => v % 1 == 0,
        message: message ?? 'Must be a whole number',
      ),
    ],
  );

  /// Validates that the value is evenly divisible by [factor].
  PkNumberSchema multipleOf(num factor, {String? message}) {
    assert(factor != 0, 'multipleOf factor must not be zero');
    return _copyWith(
      extraRules: [
        _NumberRule(
          test: (v) => v % factor == 0,
          message: message ?? 'Must be a multiple of $factor',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  @override
  ValidationResult validate(dynamic value) {
    if (value == null) {
      if (!_required) return const ValidationResult.valid(null);
      return const ValidationResult.invalid({'_': 'This field is required'});
    }

    final num? parsed = switch (value) {
      num n => n,
      String s => num.tryParse(s),
      _ => null,
    };

    if (parsed == null) {
      return const ValidationResult.invalid({'_': 'Must be a number'});
    }

    for (final rule in _rules) {
      if (!rule.test(parsed)) {
        return ValidationResult.invalid({'_': rule.message});
      }
    }

    return ValidationResult.valid(parsed);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  PkNumberSchema _copyWith({
    bool? required,
    List<_NumberRule> extraRules = const [],
  }) => PkNumberSchema._(
    required: required ?? _required,
    rules: [..._rules, ...extraRules],
  );
}

// ---------------------------------------------------------------------------
// Internal rule representation
// ---------------------------------------------------------------------------

final class _NumberRule {
  const _NumberRule({required this.test, required this.message});

  final bool Function(num value) test;
  final String message;
}
