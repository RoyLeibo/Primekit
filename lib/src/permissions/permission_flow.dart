import 'package:flutter/material.dart';

import '../core/logger.dart';
import 'permission_helper.dart';

/// A single permission request step within a [PermissionFlow].
///
/// [required] controls whether the flow considers the overall result a failure
/// when this permission is not granted.
final class PermissionRequest {
  const PermissionRequest({
    required this.permission,
    required this.title,
    required this.message,
    this.icon,
    this.required = true,
  });

  /// The permission to request.
  final PkPermission permission;

  /// Short title shown in the rationale dialog.
  final String title;

  /// Longer explanation shown below the title.
  final String message;

  /// Optional icon shown in the rationale dialog.
  final IconData? icon;

  /// Whether this permission is mandatory for the feature to function.
  ///
  /// When `false` the flow continues even if this permission is denied.
  final bool required;
}

/// The outcome of a completed [PermissionFlow].
final class PermissionFlowResult {
  const PermissionFlowResult({required this.statuses});

  /// The resolved [PkPermissionStatus] for every requested permission.
  final Map<PkPermission, PkPermissionStatus> statuses;

  /// Returns `true` if every permission in [statuses] was granted.
  bool get allGranted =>
      statuses.values.every((s) => s == PkPermissionStatus.granted);

  /// Returns `true` if every permission that had `required: true` was granted.
  bool requiredGrantedFor(List<PermissionRequest> requests) {
    for (final req in requests) {
      if (!req.required) continue;
      final s = statuses[req.permission];
      if (s == null || s != PkPermissionStatus.granted) return false;
    }
    return true;
  }

  /// Convenience getter that returns `true` when all statuses are granted.
  bool get requiredGranted => allGranted;
}

/// Displays a multi-step rationale dialog then requests each permission
/// sequentially before returning a [PermissionFlowResult].
///
/// ```dart
/// final result = await PermissionFlow.request(
///   context,
///   [
///     PermissionRequest(
///       permission: PkPermission.camera,
///       title: 'Camera access',
///       message: 'Required to scan QR codes.',
///       icon: Icons.camera_alt,
///     ),
///     PermissionRequest(
///       permission: PkPermission.microphone,
///       title: 'Microphone access',
///       message: 'Required for voice notes.',
///       icon: Icons.mic,
///       required: false,
///     ),
///   ],
/// );
///
/// if (result.requiredGrantedFor(requests)) {
///   // proceed
/// }
/// ```
abstract final class PermissionFlow {
  static const String _tag = 'PermissionFlow';

  /// Runs the permission flow for each item in [permissions].
  ///
  /// For permissions that are already granted, the rationale dialog is skipped.
  /// For permissions that are permanently denied, the user is offered the
  /// option to open system settings.
  ///
  /// Returns a [PermissionFlowResult] summarising all outcomes.
  static Future<PermissionFlowResult> request(
    BuildContext context,
    List<PermissionRequest> permissions,
  ) async {
    assert(
      permissions.isNotEmpty,
      'PermissionFlow requires at least one permission',
    );

    final statuses = <PkPermission, PkPermissionStatus>{};

    for (final req in permissions) {
      if (!context.mounted) break;

      final current = await PermissionHelper.status(req.permission);

      if (current == PkPermissionStatus.granted) {
        statuses[req.permission] = current;
        PrimekitLogger.verbose(
          '${req.permission.name} already granted, skipping.',
          tag: _tag,
        );
        continue;
      }

      if (current == PkPermissionStatus.permanentlyDenied) {
        if (context.mounted) {
          await _showPermanentlyDeniedDialog(context, req);
        }
        statuses[req.permission] = current;
        continue;
      }

      // Show rationale then request.
      if (context.mounted) {
        final shouldRequest = await _showRationaleDialog(context, req);
        if (!shouldRequest) {
          statuses[req.permission] = current;
          continue;
        }
      }

      final granted = await PermissionHelper.request(req.permission);
      final result = granted
          ? PkPermissionStatus.granted
          : await PermissionHelper.status(req.permission);
      statuses[req.permission] = result;

      PrimekitLogger.info(
        'PermissionFlow: ${req.permission.name} → ${result.name}',
        tag: _tag,
      );

      if (result == PkPermissionStatus.permanentlyDenied && context.mounted) {
        await _showPermanentlyDeniedDialog(context, req);
      }
    }

    return PermissionFlowResult(statuses: Map.unmodifiable(statuses));
  }

  // ---------------------------------------------------------------------------
  // Private dialog helpers
  // ---------------------------------------------------------------------------

  static Future<bool> _showRationaleDialog(
    BuildContext context,
    PermissionRequest req,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RationaleDialog(request: req),
    );
    return result ?? false;
  }

  static Future<void> _showPermanentlyDeniedDialog(
    BuildContext context,
    PermissionRequest req,
  ) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${req.title} denied'),
      content: Text(
        'You have permanently denied ${req.title.toLowerCase()}. '
        'To enable it, please open your device settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await PermissionHelper.openSettings();
          },
          child: const Text('Open settings'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Rationale dialog widget
// ---------------------------------------------------------------------------

class _RationaleDialog extends StatelessWidget {
  const _RationaleDialog({required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          if (request.icon != null) ...[
            Icon(request.icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(request.title)),
        ],
      ),
      content: Text(request.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
