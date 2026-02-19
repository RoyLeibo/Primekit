/// Primekit Forms module.
///
/// Zod-like schema validation for Dart. Define schemas once, validate
/// everywhere — form inputs, API responses, local storage, user data.
///
/// ```dart
/// import 'package:primekit/forms.dart';
///
/// final schema = PkSchema.object({
///   'email': PkSchema.string().email().required(),
///   'age':   PkSchema.number().min(0).max(150).integer().required(),
/// });
///
/// final result = schema.validate(formData);
/// result.isValid;           // bool
/// result.errorFor('email'); // 'Invalid email address' | null
/// ```
library primekit_forms;

export 'src/forms/forms.dart';
