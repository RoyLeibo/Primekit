import 'pk_schema.dart';

/// A schema that validates a [Map<String, dynamic>] by delegating each key
/// to its corresponding child schema.
///
/// Errors are keyed by field name, making this directly usable with form UIs:
///
/// ```dart
/// final schema = PkSchema.object({
///   'email': PkSchema.string().email().required(),
///   'age':   PkSchema.number().min(0).max(150).required(),
///   'name':  PkSchema.string().minLength(2).maxLength(100),
/// });
///
/// final result = schema.validate({'email': 'bad', 'age': 200});
/// result.errors   // {'email': 'Invalid email format', 'age': 'Must be ≤ 150'}
/// result.isValid  // false
/// ```
final class PkObjectSchema extends PkSchema<Map<String, dynamic>> {
  /// Creates an object schema backed by [fields].
  ///
  /// [fields] maps field names to their individual schemas.
  PkObjectSchema(Map<String, PkSchema<dynamic>> fields)
    : _fields = Map.unmodifiable(fields),
      _required = true,
      _refinements = const [];

  PkObjectSchema._({
    required Map<String, PkSchema<dynamic>> fields,
    required bool required,
    required List<_Refinement> refinements,
  }) : _fields = Map.unmodifiable(fields),
       _required = required,
       _refinements = refinements;

  final Map<String, PkSchema<dynamic>> _fields;
  final bool _required;
  final List<_Refinement> _refinements;

  @override
  bool get isRequired => _required;

  /// Returns an unmodifiable view of the field schemas.
  Map<String, PkSchema<dynamic>> get fields => _fields;

  // ---------------------------------------------------------------------------
  // Builder methods
  // ---------------------------------------------------------------------------

  /// Marks the object as required (the default).
  PkObjectSchema required() =>
      PkObjectSchema._(fields: _fields, required: true, refinements: _refinements);

  /// Marks the object as optional.
  ///
  /// A null value will produce a valid result with a null value.
  PkObjectSchema optional() =>
      PkObjectSchema._(fields: _fields, required: false, refinements: _refinements);

  /// Adds a cross-field validation rule.
  ///
  /// [fn] receives the fully-validated field map and must return `true` when
  /// the data is acceptable. [message] is stored under the `'_'` key in
  /// [ValidationResult.errors] when the refinement fails.
  ///
  /// Example — ensure password matches confirmPassword:
  /// ```dart
  /// final schema = PkSchema.object({
  ///   'password':        PkSchema.string().minLength(8).required(),
  ///   'confirmPassword': PkSchema.string().required(),
  /// }).refine(
  ///   (data) => data['password'] == data['confirmPassword'],
  ///   message: 'Passwords do not match',
  /// );
  /// ```
  PkObjectSchema refine(
    bool Function(Map<String, dynamic>) fn, {
    required String message,
  }) =>
      PkObjectSchema._(
        fields: _fields,
        required: _required,
        refinements: [..._refinements, _Refinement(fn: fn, message: message)],
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

    if (value is! Map) {
      return const ValidationResult.invalid({'_': 'Must be an object'});
    }

    final input = Map<String, dynamic>.from(value);
    final errors = <String, String>{};
    final validatedValues = <String, dynamic>{};

    for (final entry in _fields.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;
      final fieldValue = input[fieldName];

      final result = fieldSchema.validate(fieldValue);

      if (!result.isValid) {
        // Prefer the field-keyed error; fall back to the generic '_' error.
        final error =
            result.errorFor('_') ?? result.firstError ?? 'Invalid value';
        errors[fieldName] = error;
      } else {
        validatedValues[fieldName] = result.value;
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors);
    }

    // Run cross-field refinements only when all fields are individually valid.
    for (final refinement in _refinements) {
      if (!refinement.fn(validatedValues)) {
        return ValidationResult.invalid({'_': refinement.message});
      }
    }

    return ValidationResult.valid(
      Map<String, dynamic>.unmodifiable(validatedValues),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal refinement representation
// ---------------------------------------------------------------------------

final class _Refinement {
  const _Refinement({required this.fn, required this.message});

  final bool Function(Map<String, dynamic>) fn;
  final String message;
}
