import 'package:flutter/material.dart';

import '../invite_code.dart';

/// A reusable form widget for joining by invite code.
///
/// Displays a large code input with validation and a join button.
/// The app provides the [onJoin] callback to handle the actual join logic.
///
/// ```dart
/// InviteJoinForm(
///   onJoin: (code) async {
///     await myRepo.joinByCode(code);
///   },
///   title: 'Join Group',
///   subtitle: 'Enter the 6-digit code shared by your group member',
///   icon: Icons.group_add,
/// )
/// ```
class InviteJoinForm extends StatefulWidget {
  const InviteJoinForm({
    super.key,
    required this.onJoin,
    this.initialCode,
    this.title = 'Enter Invite Code',
    this.subtitle,
    this.icon = Icons.group_add,
    this.codeLength = 6,
    this.buttonLabel = 'Join',
    this.onSuccess,
    this.onError,
  });

  /// Called with the validated code when the user taps Join.
  final Future<void> Function(String code) onJoin;

  /// Pre-filled code (e.g., from a deep link).
  final String? initialCode;

  /// Title shown above the input.
  final String title;

  /// Subtitle shown below the title.
  final String? subtitle;

  /// Icon shown above the title.
  final IconData icon;

  /// Expected code length for validation.
  final int codeLength;

  /// Button label.
  final String buttonLabel;

  /// Called on successful join.
  final VoidCallback? onSuccess;

  /// Called with error message on failure.
  final void Function(String error)? onError;

  @override
  State<InviteJoinForm> createState() => _InviteJoinFormState();
}

class _InviteJoinFormState extends State<InviteJoinForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleJoin());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an invite code';
    }
    final trimmed = value.trim();
    if (trimmed.length != widget.codeLength) {
      return 'Code must be ${widget.codeLength} characters';
    }
    if (widget.codeLength == 6 && !InviteCode.isValidCode(trimmed)) {
      return 'Code must contain only digits';
    }
    return null;
  }

  Future<void> _handleJoin() async {
    final code = widget.initialCode ?? _controller.text.trim();

    if (widget.initialCode == null) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onJoin(code);
      widget.onSuccess?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // If auto-joining from a deep link, show loading.
    if (widget.initialCode != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 24),
            Text('Joining...', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your invitation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Manual entry form.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(widget.icon, size: 64, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter ${widget.codeLength}-digit code',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.pin_rounded),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
              maxLength: widget.codeLength,
              validator: _validate,
              autofocus: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _handleJoin,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
