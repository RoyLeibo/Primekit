export 'permission.dart' show Permission, Role;
// firebase_rbac_provider.dart is NOT exported here — it requires Firebase.
// Import it directly: import 'package:primekit/src/rbac/providers/firebase_rbac_provider.dart';
export 'providers/mongo_rbac_provider.dart' show MongoRbacProvider;
export 'rbac_context.dart' show RbacContext;
export 'rbac_policy.dart' show RbacPolicy;
export 'rbac_provider.dart' show RbacProvider;
export 'rbac_service.dart' show RbacService;
export 'sharing_mixin.dart' show PkSharingMixin, SharingException;
export 'sharing_models.dart' show PkMember, PkShareRole, PkSharingConfig;
export 'widgets/permission_gate.dart' show RbacGate;
