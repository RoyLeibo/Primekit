import 'pk_schema.dart';
import 'validation_result.dart';

/// A schema that validates a [List] where each element is validated by
/// [itemSchema].
///
/// ```dart
/// final tagsSchema = PkSchema.list(PkSchema.string().notEmpty()).required();
/// final result = tagsSchema.validate(['dart', '', 'flutter']);
/// // result.errors → {'[1]': 'Must not be empty'}
/// ```
final class PkListSchema<T> extends PkSchema<List<T>> {
  PkListSchema._(
    this._itemSchema, {
    required bool required,
    required List<_ListRule<T>> rules,
  }) : _required = required,
       _rules = rules;

  /// Creates a new list schema where each item is validated by [itemSchema].
  PkListSchema(PkSchema<T> itemSchema)
    : _itemSchema = itemSchema,
      _required = true,
      _rules = const [];

  final PkSchema<T> _itemSchema;
  final bool _required;
  final List<_ListRule<T>> _rules;

  @override
  bool get isRequired => _required;

  // ---------------------------------------------------------------------------
  // Builder methods
  // ---------------------------------------------------------------------------

  /// Marks the field as required (the default).
  PkListSchema<T> required({String? message}) => _copyWith(required: true);

  /// Marks the field as optional.
  PkListSchema<T> optional() => _copyWith(required: false);

  /// Validates that the list has at least [min] elements.
  PkListSchema<T> minItems(int min, {String? message}) => _copyWith(
    extraRules: [
      _ListRule(
        test: (v) => v.length >= min,
        message: message ?? 'Must have at least $min item(s)',
      ),
    ],
  );

  /// Validates that the list has at most [max] elements.
  PkListSchema<T> maxItems(int max, {String? message}) => _copyWith(
    extraRules: [
      _ListRule(
        test: (v) => v.length <= max,
        message: message ?? 'Must have at most $max item(s)',
      ),
    ],
  );

  /// Validates that the list is not empty.
  PkListSchema<T> notEmpty({String? message}) => _copyWith(
    extraRules: [
      _ListRule(
        test: (v) => v.isNotEmpty,
        message: message ?? 'List must not be empty',
      ),
    ],
  );

  /// Validates that all list elements are unique.
  PkListSchema<T> unique({String? message}) => _copyWith(
    extraRules: [
      _ListRule(
        test: (v) => v.toSet().length == v.length,
        message: message ?? 'All items must be unique',
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

    if (value is! List) {
      return const ValidationResult.invalid({'_': 'Must be a list'});
    }

    // Apply list-level rules before checking individual items.
    final typedList = value.cast<dynamic>();
    for (final rule in _rules) {
      if (!rule.test(typedList)) {
        return ValidationResult.invalid({'_': rule.message});
      }
    }

    // Validate each item and collect errors keyed by index.
    final itemErrors = <String, String>{};
    final validatedItems = <T>[];

    for (var i = 0; i < typedList.length; i++) {
      final itemResult = _itemSchema.validate(typedList[i]);
      if (!itemResult.isValid) {
        final itemError = itemResult.firstError ?? 'Invalid value';
        itemErrors['[$i]'] = itemError;
      } else {
        validatedItems.add(itemResult.value as T);
      }
    }

    if (itemErrors.isNotEmpty) {
      return ValidationResult.invalid(itemErrors);
    }

    return ValidationResult.valid(List<T>.unmodifiable(validatedItems));
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  PkListSchema<T> _copyWith({
    bool? required,
    List<_ListRule<T>> extraRules = const [],
  }) => PkListSchema<T>._(
    _itemSchema,
    required: required ?? _required,
    rules: [..._rules, ...extraRules],
  );
}

// ---------------------------------------------------------------------------
// Internal rule representation
// ---------------------------------------------------------------------------

final class _ListRule<T> {
  const _ListRule({required this.test, required this.message});

  final bool Function(List<dynamic> value) test;
  final String message;
}
