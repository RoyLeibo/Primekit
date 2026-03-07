import 'pk_bool_schema.dart';
import 'pk_date_schema.dart';
import 'pk_list_schema.dart';
import 'pk_number_schema.dart';
import 'pk_object_schema.dart';
import 'pk_string_schema.dart';
import 'validation_result.dart';

export 'pk_bool_schema.dart';
export 'pk_date_schema.dart';
export 'pk_list_schema.dart';
export 'pk_number_schema.dart';
export 'pk_object_schema.dart';
export 'pk_string_schema.dart';
export 'validation_result.dart';

/// The abstract base for all Primekit schema validators.
///
/// Use the static factory methods to create typed schemas, then chain
/// modifier methods to configure validation rules:
///
/// ```dart
/// final schema = PkSchema.object({
///   'email':   PkSchema.string().email().required(),
///   'age':     PkSchema.number().min(0).max(150).required(),
///   'website': PkSchema.string().url().optional(),
/// });
///
/// final result = schema.validate({'email': 'bad', 'age': 200});
/// result.errors   // {'email': 'Invalid email format', 'age': 'Must be ≤ 150'}
/// result.isValid  // false
/// ```
abstract class PkSchema<T> {
  const PkSchema();

  /// Validates [value] against this schema's rules.
  ValidationResult validate(dynamic value);

  /// Whether this field is required (null / absent values are rejected).
  bool get isRequired;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a string schema.
  static PkStringSchema string() => PkStringSchema();

  /// Creates a numeric schema (int or double).
  static PkNumberSchema number() => PkNumberSchema();

  /// Creates a boolean schema.
  // ignore: non_constant_identifier_names — matches Zod API convention
  static PkBoolSchema boolean() => PkBoolSchema();

  /// Creates an object schema backed by [fields].
  static PkObjectSchema object(Map<String, PkSchema<dynamic>> fields) =>
      PkObjectSchema(fields);

  /// Creates a list schema where each element is validated by [itemSchema].
  static PkListSchema<T> list<T>(PkSchema<T> itemSchema) =>
      PkListSchema<T>(itemSchema);

  /// Creates a date schema.
  static PkDateSchema date() => PkDateSchema();
}
