import 'pk_schema.dart';
import 'validation_result.dart';

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
      _required = true;

  PkObjectSchema._({
    required Map<String, PkSchema<dynamic>> fields,
    required bool required,
  }) : _fields = Map.unmodifiable(fields),
       _required = required;

  final Map<String, PkSchema<dynamic>> _fields;
  final bool _required;

  @override
  bool get isRequired => _required;

  /// Returns an unmodifiable view of the field schemas.
  Map<String, PkSchema<dynamic>> get fields => _fields;

  // ---------------------------------------------------------------------------
  // Builder methods
  // ---------------------------------------------------------------------------

  /// Marks the object as required (the default).
  PkObjectSchema required() =>
      PkObjectSchema._(fields: _fields, required: true);

  /// Marks the object as optional.
  ///
  /// A null value will produce a valid result with a null value.
  PkObjectSchema optional() =>
      PkObjectSchema._(fields: _fields, required: false);

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

    return ValidationResult.valid(
      Map<String, dynamic>.unmodifiable(validatedValues),
    );
  }
}
