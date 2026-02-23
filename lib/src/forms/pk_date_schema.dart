import 'pk_schema.dart';

/// A schema that validates [DateTime] values.
///
/// Accepts Dart [DateTime] instances and ISO-8601 strings.
///
/// ```dart
/// final birthdaySchema = PkSchema.date()
///     .before(DateTime.now())
///     .after(DateTime(1900))
///     .required();
/// ```
final class PkDateSchema extends PkSchema<DateTime> {
  PkDateSchema._({required bool required, required List<_DateRule> rules})
    : _required = required,
      _rules = rules;

  /// Creates a new date schema with no constraints.
  PkDateSchema() : _required = true, _rules = const [];

  final bool _required;
  final List<_DateRule> _rules;

  @override
  bool get isRequired => _required;

  // ---------------------------------------------------------------------------
  // Builder methods
  // ---------------------------------------------------------------------------

  /// Marks the field as required (the default).
  PkDateSchema required({String? message}) => _copyWith(required: true);

  /// Marks the field as optional.
  PkDateSchema optional() => _copyWith(required: false);

  /// Validates that the date is after [date] (exclusive).
  PkDateSchema after(DateTime date, {String? message}) => _copyWith(
    extraRules: [
      _DateRule(
        test: (v) => v.isAfter(date),
        message: message ?? 'Must be after ${date.toIso8601String()}',
      ),
    ],
  );

  /// Validates that the date is before [date] (exclusive).
  PkDateSchema before(DateTime date, {String? message}) => _copyWith(
    extraRules: [
      _DateRule(
        test: (v) => v.isBefore(date),
        message: message ?? 'Must be before ${date.toIso8601String()}',
      ),
    ],
  );

  /// Validates that the date is on or after [date].
  PkDateSchema notBefore(DateTime date, {String? message}) => _copyWith(
    extraRules: [
      _DateRule(
        test: (v) => !v.isBefore(date),
        message: message ?? 'Must not be before ${date.toIso8601String()}',
      ),
    ],
  );

  /// Validates that the date is on or before [date].
  PkDateSchema notAfter(DateTime date, {String? message}) => _copyWith(
    extraRules: [
      _DateRule(
        test: (v) => !v.isAfter(date),
        message: message ?? 'Must not be after ${date.toIso8601String()}',
      ),
    ],
  );

  /// Validates that the date is in the past (before now).
  PkDateSchema inPast({String? message}) => _copyWith(
    extraRules: [
      _DateRule(
        test: (v) => v.isBefore(DateTime.now()),
        message: message ?? 'Must be a date in the past',
      ),
    ],
  );

  /// Validates that the date is in the future (after now).
  PkDateSchema inFuture({String? message}) => _copyWith(
    extraRules: [
      _DateRule(
        test: (v) => v.isAfter(DateTime.now()),
        message: message ?? 'Must be a date in the future',
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

    final DateTime? parsed = switch (value) {
      DateTime dt => dt,
      String s => DateTime.tryParse(s),
      _ => null,
    };

    if (parsed == null) {
      return const ValidationResult.invalid({
        '_': 'Must be a valid date or ISO-8601 string',
      });
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

  PkDateSchema _copyWith({
    bool? required,
    List<_DateRule> extraRules = const [],
  }) => PkDateSchema._(
    required: required ?? _required,
    rules: [..._rules, ...extraRules],
  );
}

// ---------------------------------------------------------------------------
// Internal rule representation
// ---------------------------------------------------------------------------

final class _DateRule {
  const _DateRule({required this.test, required this.message});

  final bool Function(DateTime value) test;
  final String message;
}
