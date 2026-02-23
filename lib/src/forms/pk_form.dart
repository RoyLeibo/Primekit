import 'package:flutter/material.dart';

import 'pk_object_schema.dart';
import 'validation_result.dart';

/// Controller vended to [PkForm]'s builder that lets child widgets read
/// form state and trigger actions imperatively.
///
/// ```dart
/// PkForm(
///   schema: mySchema,
///   onSubmit: (values) async { ... },
///   builder: (controller) => Column(children: [
///     TextButton(
///       onPressed: controller.isSubmitting ? null : controller.submit,
///       child: const Text('Submit'),
///     ),
///   ]),
/// )
/// ```
class PkFormController extends ChangeNotifier {
  PkFormController._({
    required PkObjectSchema schema,
    required Future<void> Function(Map<String, dynamic>) onSubmit,
  }) : _schema = schema,
       _onSubmit = onSubmit;

  final PkObjectSchema _schema;
  final Future<void> Function(Map<String, dynamic>) _onSubmit;

  Map<String, dynamic> _values = {};
  Map<String, String> _errors = {};
  bool _isSubmitting = false;

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  /// The current field values collected from all registered fields.
  Map<String, dynamic> get values => Map.unmodifiable(_values);

  /// The current field-level validation errors produced by the schema.
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// Whether the current values satisfy the schema without errors.
  bool get isValid => _validateSchema().isValid;

  /// Whether a submit operation is in progress.
  bool get isSubmitting => _isSubmitting;

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Updates the value for [fieldName] and re-validates the affected field.
  void setValue(String fieldName, dynamic value) {
    _values = {..._values, fieldName: value};
    _revalidate();
    notifyListeners();
  }

  /// Resets all values and errors to their initial empty state.
  void reset() {
    _values = {};
    _errors = {};
    _isSubmitting = false;
    notifyListeners();
  }

  /// Runs full schema validation. If valid, calls the form's [onSubmit]
  /// callback with the current values; otherwise exposes errors.
  ///
  /// Returns immediately without calling [onSubmit] when already submitting.
  Future<void> submit() async {
    if (_isSubmitting) return;

    final result = _validateSchema();
    if (!result.isValid) {
      _errors = Map.unmodifiable(result.errors);
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _errors = {};
    notifyListeners();

    try {
      await _onSubmit(Map<String, dynamic>.unmodifiable(_values));
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Returns the error message for [fieldName], or `null` if there is none.
  String? errorFor(String fieldName) => _errors[fieldName];

  /// Returns `true` if [fieldName] currently has a validation error.
  bool hasError(String fieldName) => _errors.containsKey(fieldName);

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _revalidate() {
    final result = _validateSchema();
    _errors = result.isValid ? const {} : Map.unmodifiable(result.errors);
  }

  ValidationResult _validateSchema() => _schema.validate(_values);
}

/// A container widget that manages a group of fields validated by a
/// [PkObjectSchema].
///
/// Provides a [PkFormController] to the [builder] function; child widgets
/// call [PkFormController.setValue] to register their values and
/// [PkFormController.submit] to trigger validation and submission.
///
/// ```dart
/// PkForm(
///   schema: PkSchema.object({
///     'email':    PkSchema.string().email().required(),
///     'password': PkSchema.string().minLength(8).required(),
///   }),
///   onSubmit: (values) async {
///     await authService.signIn(
///       values['email'] as String,
///       values['password'] as String,
///     );
///   },
///   builder: (controller) => Column(
///     children: [
///       TextField(
///         onChanged: (v) => controller.setValue('email', v),
///         decoration: InputDecoration(
///           labelText: 'Email',
///           errorText: controller.errorFor('email'),
///         ),
///       ),
///       TextField(
///         obscureText: true,
///         onChanged: (v) => controller.setValue('password', v),
///         decoration: InputDecoration(
///           labelText: 'Password',
///           errorText: controller.errorFor('password'),
///         ),
///       ),
///       ListenableBuilder(
///         listenable: controller,
///         builder: (_, __) => ElevatedButton(
///           onPressed: controller.isSubmitting ? null : controller.submit,
///           child: controller.isSubmitting
///               ? const CircularProgressIndicator()
///               : const Text('Sign in'),
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
class PkForm extends StatefulWidget {
  const PkForm({
    super.key,
    required this.schema,
    required this.builder,
    required this.onSubmit,
  });

  /// The schema that defines validation rules for all fields.
  final PkObjectSchema schema;

  /// Builder that receives a [PkFormController] and returns the form UI.
  ///
  /// Rebuilt whenever the controller notifies listeners.
  final Widget Function(PkFormController controller) builder;

  /// Called with validated values when the form is submitted successfully.
  final Future<void> Function(Map<String, dynamic> values) onSubmit;

  @override
  State<PkForm> createState() => _PkFormState();
}

class _PkFormState extends State<PkForm> {
  late final PkFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PkFormController._(
      schema: widget.schema,
      onSubmit: widget.onSubmit,
    )..addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      PkFormScope(controller: _controller, child: widget.builder(_controller));
}

/// An [InheritedWidget] that makes [PkFormController] available to all
/// descendant widgets.
///
/// Use [PkFormScope.of] to access the nearest controller without requiring
/// it to be threaded through constructors.
class PkFormScope extends InheritedWidget {
  const PkFormScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The controller managing the enclosing form.
  final PkFormController controller;

  /// Returns the [PkFormController] from the nearest [PkFormScope], or
  /// `null` if there is no ancestor [PkFormScope].
  static PkFormController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PkFormScope>()?.controller;

  @override
  bool updateShouldNotify(PkFormScope oldWidget) =>
      controller != oldWidget.controller;
}
