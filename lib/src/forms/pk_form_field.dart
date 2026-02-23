import 'dart:async';

import 'package:flutter/material.dart';

import 'pk_schema.dart';

/// A Flutter form field backed by a [PkSchema].
///
/// Validates on every keystroke with a configurable debounce delay, and
/// surfaces the schema error message as the field's decoration error text.
///
/// ```dart
/// final emailSchema = PkSchema.string().email().required();
///
/// PkFormField<String>(
///   schema: emailSchema,
///   fieldName: 'email',
///   label: 'Email address',
///   hint: 'you@example.com',
///   keyboardType: TextInputType.emailAddress,
///   onChanged: (value) => setState(() => _email = value),
/// )
/// ```
class PkFormField<T> extends StatefulWidget {
  const PkFormField({
    super.key,
    required this.schema,
    required this.fieldName,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.decoration,
    this.debounceMilliseconds = 350,
    this.validateOnMount = false,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
  });

  /// The schema that drives validation for this field.
  final PkSchema<T> schema;

  /// A unique name used to identify this field within a [PkForm].
  final String fieldName;

  /// An optional controller. If omitted, an internal controller is managed.
  final TextEditingController? controller;

  /// Label text displayed above the field.
  final String? label;

  /// Placeholder hint text.
  final String? hint;

  /// Whether the text is obscured (password fields).
  final bool obscureText;

  /// Callback invoked with the validated value (or `null` on validation failure).
  final void Function(T? value)? onChanged;

  /// Keyboard type for the field.
  final TextInputType? keyboardType;

  /// Override the complete input decoration.
  ///
  /// When provided, [label] and [hint] are ignored.
  final InputDecoration? decoration;

  /// Milliseconds of inactivity before validation runs. Default: 350 ms.
  final int debounceMilliseconds;

  /// If `true`, validation runs immediately when the widget mounts.
  final bool validateOnMount;

  /// The keyboard action button to show.
  final TextInputAction? textInputAction;

  /// Maximum number of lines. Defaults to 1.
  final int maxLines;

  /// Whether the field is interactive.
  final bool enabled;

  @override
  State<PkFormField<T>> createState() => _PkFormFieldState<T>();
}

class _PkFormFieldState<T> extends State<PkFormField<T>> {
  late TextEditingController _controller;
  bool _ownsController = false;

  String? _errorText;
  Timer? _debounce;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }

    _controller.addListener(_onTextChanged);

    if (widget.validateOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runValidation());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _isDirty = true;
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: widget.debounceMilliseconds),
      _runValidation,
    );
  }

  void _runValidation() {
    if (!mounted) return;
    final raw = _controller.text;
    final result = widget.schema.validate(raw.isEmpty ? null : raw);
    final errorText = result.isValid ? null : result.firstError;

    setState(() => _errorText = errorText);

    if (widget.onChanged != null) {
      widget.onChanged!(result.isValid ? result.value as T? : null);
    }
  }

  /// Programmatically run validation and return the result.
  ValidationResult runValidation() {
    _isDirty = true;
    final raw = _controller.text;
    final result = widget.schema.validate(raw.isEmpty ? null : raw);
    final errorText = result.isValid ? null : result.firstError;
    if (mounted) setState(() => _errorText = errorText);
    return result;
  }

  /// Returns the raw text currently in the field.
  String get rawValue => _controller.text;

  /// Returns `true` if the current value passes schema validation.
  bool get isValid {
    final raw = _controller.text;
    return widget.schema.validate(raw.isEmpty ? null : raw).isValid;
  }

  InputDecoration _buildDecoration() {
    if (widget.decoration != null) {
      return widget.decoration!.copyWith(errorText: _errorText);
    }
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      errorText: _isDirty ? _errorText : null,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    obscureText: widget.obscureText,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    maxLines: widget.obscureText ? 1 : widget.maxLines,
    enabled: widget.enabled,
    decoration: _buildDecoration(),
  );
}
