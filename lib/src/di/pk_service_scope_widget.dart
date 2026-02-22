/// Flutter widget that provides a [ServiceScope] to a subtree.
library primekit_service_scope_widget;

import 'package:flutter/widgets.dart';

import 'service_locator.dart';
import 'service_scope.dart';

/// An [InheritedWidget] that creates a [ServiceScope] for its subtree and
/// disposes it when removed from the tree.
///
/// Place [PkServiceScopeWidget] at the root of a screen or feature subtree.
/// Descendants call [PkServiceScopeWidget.scopeOf] to resolve services from
/// the scoped [ServiceScope], or [PkServiceScopeWidget.of] to obtain the
/// underlying [ServiceLocator].
///
/// ```dart
/// PkServiceScopeWidget(
///   parent: ServiceLocator.instance,
///   child: MyScreen(),
/// )
///
/// // Inside MyScreen or any descendant:
/// final scope = PkServiceScopeWidget.scopeOf(context);
/// final bloc = scope.get<MyBloc>();
/// ```
class PkServiceScopeWidget extends StatefulWidget {
  /// Creates a [PkServiceScopeWidget] that inherits registrations from
  /// [parent].
  const PkServiceScopeWidget({
    super.key,
    required this.parent,
    required this.child,
  });

  /// The parent [ServiceLocator] whose registrations are inherited.
  final ServiceLocator parent;

  /// The subtree that has access to the created [ServiceScope].
  final Widget child;

  /// Returns the [ServiceScope] provided by the nearest
  /// [PkServiceScopeWidget] ancestor.
  ///
  /// Throws a [FlutterError] if no ancestor [PkServiceScopeWidget] is found.
  static ServiceScope scopeOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_ServiceScopeInherited>();
    if (inherited == null) {
      throw FlutterError(
        'PkServiceScopeWidget.scopeOf() called with a context that does not '
        'contain a PkServiceScopeWidget.\n'
        'Ensure a PkServiceScopeWidget ancestor exists in the widget tree.',
      );
    }
    return inherited.scope;
  }

  /// Returns the [ServiceLocator] provided by the nearest
  /// [PkServiceScopeWidget] ancestor.
  ///
  /// Convenience alias: resolves via [scopeOf] and provides access to the
  /// parent locator for non-scoped registrations. For scoped resolution,
  /// prefer [scopeOf].
  static ServiceLocator of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ServiceScopeInherited>()
          ?.locator ??
      (throw FlutterError(
        'PkServiceScopeWidget.of() called with a context that does not '
        'contain a PkServiceScopeWidget.\n'
        'Ensure a PkServiceScopeWidget ancestor exists in the widget tree.',
      ));

  @override
  State<PkServiceScopeWidget> createState() => _PkServiceScopeWidgetState();
}

class _PkServiceScopeWidgetState extends State<PkServiceScopeWidget> {
  late final ServiceScope _scope;

  @override
  void initState() {
    super.initState();
    _scope = ServiceScope.of(widget.parent);
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ServiceScopeInherited(
        scope: _scope,
        locator: widget.parent,
        child: widget.child,
      );
}

/// Internal [InheritedWidget] that distributes the [ServiceScope] and
/// [ServiceLocator] to descendants.
class _ServiceScopeInherited extends InheritedWidget {
  const _ServiceScopeInherited({
    required this.scope,
    required this.locator,
    required super.child,
  });

  final ServiceScope scope;
  final ServiceLocator locator;

  @override
  bool updateShouldNotify(_ServiceScopeInherited oldWidget) =>
      scope != oldWidget.scope || locator != oldWidget.locator;
}
