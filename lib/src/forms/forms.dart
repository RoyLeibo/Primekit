/// Forms — Zod-inspired schema validation for Dart and Flutter.
///
/// Define schemas once and validate anywhere — from raw business logic
/// to Flutter form fields:
///
/// ```dart
/// final schema = PkSchema.object({
///   'email':   PkSchema.string().email().required(),
///   'age':     PkSchema.number().min(0).max(150).required(),
///   'website': PkSchema.string().url().optional(),
/// });
///
/// final result = schema.validate({'email': 'bad', 'age': 200});
/// result.isValid  // false
/// result.errors   // {'email': 'Invalid email format', 'age': 'Must be ≤ 150'}
/// ```
library primekit_forms;

export 'pk_schema.dart';
export 'pk_string_schema.dart';
export 'pk_number_schema.dart';
export 'pk_bool_schema.dart';
export 'pk_object_schema.dart';
export 'pk_list_schema.dart';
export 'pk_date_schema.dart';
export 'validation_result.dart';
export 'pk_form_field.dart';
export 'pk_form.dart';
