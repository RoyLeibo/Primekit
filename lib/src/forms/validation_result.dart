/// The result of a schema validation operation.
///
/// Use [ValidationResult.valid] when all rules pass and [ValidationResult.invalid]
/// when one or more rules fail.
///
/// ```dart
/// final result = schema.validate(input);
/// if (result.isValid) {
///   processData(result.value);
/// } else {
///   showErrors(result.errors);
/// }
/// ```
final class ValidationResult {
  /// Creates a successful validation result with the coerced [value].
  const ValidationResult.valid(this.value)
      : isValid = true,
        errors = const {};

  /// Creates a failed validation result with [errors] keyed by field name.
  const ValidationResult.invalid(this.errors)
      : isValid = false,
        value = null;

  /// Whether all validation rules passed.
  final bool isValid;

  /// Field-level error messages. Empty when [isValid] is `true`.
  ///
  /// For scalar schemas the map has a single key `'_'`.
  /// For object schemas the map keys correspond to field names.
  final Map<String, String> errors;

  /// The validated (and possibly coerced) value.
  ///
  /// Always `null` when [isValid] is `false`.
  final dynamic value;

  /// Returns the error message for [field], or `null` if there is none.
  String? errorFor(String field) => errors[field];

  /// Returns `true` if [field] has at least one error.
  bool hasError(String field) => errors.containsKey(field);

  /// Returns the first error message across all fields, or `null` if valid.
  String? get firstError =>
      errors.isEmpty ? null : errors.values.first;

  /// Merges another [ValidationResult] into this one.
  ///
  /// Useful when combining multiple schema results. The returned result is
  /// invalid if either result is invalid.
  ValidationResult merge(ValidationResult other) {
    if (isValid && other.isValid) return ValidationResult.valid(value);
    final merged = {
      ...errors,
      ...other.errors,
    };
    return ValidationResult.invalid(merged);
  }

  @override
  String toString() => isValid
      ? 'ValidationResult.valid($value)'
      : 'ValidationResult.invalid($errors)';
}
