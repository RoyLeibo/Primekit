# forms — Schema-Based Validation

**Purpose:** Zod-inspired fluent schema validation for form inputs.

**Key exports:**
- `PkSchema` — factory class: `.string()`, `.number()`, `.boolean()`, `.object()`, `.list()`, `.date()`
- `PkStringSchema`, `PkNumberSchema`, etc. — specific schema builders
- `ValidationResult` — `{ isValid: bool, errors: Map<String, String> }`
- `PkForm` — Flutter widget that wraps form fields and manages submit
- `PkFormField` — widget for individual field with validation display
- `PkFormController` — manages form values, errors, submission state

**Fluent API:**
```dart
final schema = PkSchema.object({
  'email': PkSchema.string().email().required(),
  'age': PkSchema.number().min(0).max(150).required(),
});
final result = schema.validate({'email': 'x@y.com', 'age': 25});
```

**Dependencies:** flutter (ChangeNotifier), `core` (ValidationException)

**Planned usage:** PawTrack (5 form screens → PkSchema)

**Maintenance:** Update when new schema modifier or validator added.
