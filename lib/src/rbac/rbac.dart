/// RBAC — role-based access control with typed permissions, resource scoping,
/// and Firebase / MongoDB backends.
///
/// Import this barrel to access the full RBAC module:
/// ```dart
/// import 'package:primekit/src/rbac/rbac.dart';
/// ```
library primekit_rbac;

export 'permission.dart' show Permission, Role;
export 'providers/firebase_rbac_provider.dart' show FirebaseRbacProvider;
export 'providers/mongo_rbac_provider.dart' show MongoRbacProvider;
export 'rbac_context.dart' show RbacContext;
export 'rbac_policy.dart' show RbacPolicy;
export 'rbac_provider.dart' show RbacProvider;
export 'rbac_service.dart' show RbacService;
export 'widgets/permission_gate.dart' show RbacGate;
