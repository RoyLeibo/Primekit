import 'pk_schema.dart';
import 'validation_result.dart';

/// A schema that validates boolean values.
///
/// Accepts Dart [bool] literals as well as the strings `'true'` / `'false'`
/// and the integers `1` / `0` for maximum form-input flexibility.
///
/// ```dart
/// final tosSchema = PkSchema.bool().mustBeTrue(message: 'You must accept the terms').required();
/// final result = tosSchema.validate(false);
/// result.isValid // false
/// ```
final class PkBoolSchema extends PkSchema<bool> {
  PkBoolSchema._({
    required bool required,
    required List<_BoolRule> rules,
  })  : _required = required,
        _rules = rules;

  /// Creates a new bool schema with no constraints.
  PkBoolSchema()
      : _required = true,
        _rules = const [];

  final bool _required;
  final List<_BoolRule> _rules;

  @override
  bool get isRequired => _required;

  // ---------------------------------------------------------------------------
  // Builder methods
  // ---------------------------------------------------------------------------

  /// Marks the field as required (the default).
  PkBoolSchema required({String? message}) => _copyWith(required: true);

  /// Marks the field as optional.
  PkBoolSchema optional() => _copyWith(required: false);

  /// Validates that the value is `true`.
  ///
  /// Useful for checkbox acceptance fields.
  PkBoolSchema mustBeTrue({String? message}) => _copyWith(
        extraRules: [
          _BoolRule(
            test: (v) => v == true,
            message: message ?? 'Must be accepted',
          ),
        ],
      );

  /// Validates that the value is `false`.
  PkBoolSchema mustBeFalse({String? message}) => _copyWith(
        extraRules: [
          _BoolRule(
            test: (v) => v == false,
            message: message ?? 'Must be declined',
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  @override
  ValidationResult validate(dynamic value) {
    if (value == null) {
      if (!_required) return const ValidationResult.valid(null);
      return const ValidationResult.invalid({'_': 'This field is required'});
    }

    final bool? parsed = switch (value) {
      bool b => b,
      String s when s.toLowerCase() == 'true' => true,
      String s when s.toLowerCase() == 'false' => false,
      1 => true,
      0 => false,
      _ => null,
    };

    if (parsed == null) {
      return const ValidationResult.invalid({'_': 'Must be a boolean'});
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

  PkBoolSchema _copyWith({
    bool? required,
    List<_BoolRule> extraRules = const [],
  }) =>
      PkBoolSchema._(
        required: required ?? _required,
        rules: [..._rules, ...extraRules],
      );
}

// ---------------------------------------------------------------------------
// Internal rule representation
// ---------------------------------------------------------------------------

final class _BoolRule {
  const _BoolRule({required this.test, required this.message});

  final bool Function(bool value) test;
  final String message;
}
