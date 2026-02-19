import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/logger.dart';
import 'permission_helper.dart';

/// A widget that checks and optionally requests a device permission before
/// rendering its [child].
///
/// The widget progresses through states:
/// 1. **Loading** — while the permission status is being read.
/// 2. **Granted** — renders [child].
/// 3. **Restricted** (iOS) — renders [restrictedView] or a default message.
/// 4. **Permanently denied** — renders [deniedView] or a default message.
/// 5. **Denied (requestable)** — if [autoRequest] is `true`, shows the
///    rationale dialog (when configured) and then requests the permission.
///
/// ```dart
/// PermissionGate(
///   permission: Permission.camera,
///   rationaleTitle: 'Camera access needed',
///   rationaleMessage: 'We need your camera to scan QR codes.',
///   child: const CameraPreview(),
///   deniedView: const PermissionDeniedBanner(feature: 'Camera'),
/// )
/// ```
class PermissionGate extends StatefulWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.deniedView,
    this.restrictedView,
    this.loadingView,
    this.rationaleTitle,
    this.rationaleMessage,
    this.autoRequest = true,
  });

  /// The permission to check/request.
  final Permission permission;

  /// Widget rendered when the permission is granted.
  final Widget child;

  /// Widget rendered when the permission is permanently denied.
  ///
  /// Defaults to a built-in message with a "Open Settings" button.
  final Widget? deniedView;

  /// Widget rendered when the permission is restricted (iOS only).
  ///
  /// Defaults to a built-in restriction message.
  final Widget? restrictedView;

  /// Widget rendered while the permission status is being resolved.
  ///
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loadingView;

  /// Title shown in the rationale dialog before the system permission dialog.
  final String? rationaleTitle;

  /// Body shown in the rationale dialog. When `null`, no rationale dialog
  /// is shown and the system dialog is requested directly.
  final String? rationaleMessage;

  /// Whether to automatically request the permission when it is not yet
  /// granted. Defaults to `true`.
  final bool autoRequest;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  PermissionStatus _status = PermissionStatus.denied;
  bool _loading = true;

  static const String _tag = 'PermissionGate';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check when the app returns to the foreground (e.g. after settings).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    setState(() => _loading = true);

    final status = await PermissionHelper.status(widget.permission);
    PrimekitLogger.verbose(
      'PermissionGate(${widget.permission}): $status',
      tag: _tag,
    );

    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _status = status;
        _loading = false;
      });
      return;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      setState(() {
        _status = status;
        _loading = false;
      });
      return;
    }

    if (widget.autoRequest) {
      await _requestWithOptionalRationale();
      return;
    }

    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _requestWithOptionalRationale() async {
    if (widget.rationaleMessage != null && mounted) {
      final shouldRequest = await _showRationaleDialog();
      if (!mounted) return;
      if (!shouldRequest) {
        final current = await PermissionHelper.status(widget.permission);
        setState(() {
          _status = current;
          _loading = false;
        });
        return;
      }
    }

    final result = await widget.permission.request();
    if (mounted) {
      setState(() {
        _status = result;
        _loading = false;
      });
    }
  }

  Future<bool> _showRationaleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.rationaleTitle ?? 'Permission required'),
        content: Text(widget.rationaleMessage!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingView ??
          const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_status.isGranted) return widget.child;

    if (_status.isRestricted) {
      return widget.restrictedView ??
          _DefaultRestrictedView(permission: widget.permission);
    }

    // Permanently denied or still denied after request.
    return widget.deniedView ??
        _DefaultDeniedView(permission: widget.permission);
  }
}

// ---------------------------------------------------------------------------
// Default fallback views
// ---------------------------------------------------------------------------

class _DefaultDeniedView extends StatelessWidget {
  const _DefaultDeniedView({required this.permission});

  final Permission permission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Permission required',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature requires a permission that has been denied. '
              'Please enable it in your device settings.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: PermissionHelper.openSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultRestrictedView extends StatelessWidget {
  const _DefaultRestrictedView({required this.permission});

  final Permission permission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Restricted by device policy',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is restricted on your device and cannot be enabled.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
