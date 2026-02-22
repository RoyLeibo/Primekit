import 'package:flutter/widgets.dart';

import '../permission.dart';
import '../rbac_service.dart';

/// A widget that conditionally renders its [child] based on the current user's
/// RBAC permissions.
///
/// This is distinct from the device-permission `PermissionGate` in the
/// permissions module — [RbacGate] checks the user's assigned roles, not
/// system permissions.
///
/// ```dart
/// RbacGate(
///   permission: Permission.write('posts'),
///   child: const EditPostButton(),
///   fallback: const SizedBox.shrink(),
/// )
/// ```
class RbacGate extends StatelessWidget {
  /// Creates an [RbacGate].
  ///
  /// [permission] — the required [Permission].
  /// [child] — widget shown when permission is granted.
  /// [fallback] — widget shown when permission is denied (defaults to
  ///   [SizedBox.shrink]).
  const RbacGate({
    required this.permission,
    required this.child,
    this.fallback,
    super.key,
  });

  /// The permission required to show [child].
  final Permission permission;

  /// Widget rendered when the user has [permission].
  final Widget child;

  /// Widget rendered when the user does not have [permission].
  ///
  /// Defaults to [SizedBox.shrink] when not provided.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: RbacService.instance,
        builder: (ctx, _) {
          final allowed = RbacService.instance.can(permission);
          return allowed ? child : (fallback ?? const SizedBox.shrink());
        },
      );
}
