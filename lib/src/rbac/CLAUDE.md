# rbac — Role-Based Access Control + Sharing

**Purpose:** Permission checking, policy enforcement, and multi-user document sharing. Backend-agnostic with Firebase/Mongo implementations.

**Key exports:**
- `RbacService` — singleton; load policies then check permissions
- `RbacPolicy` — policy definition (roles, permissions, inheritance hierarchy)
- `RbacProvider` — abstract interface for loading policies
- `Permission` — value type with `Permission.write('posts')`, `Permission.admin()`, etc.
- `Role` — role definition with assigned permissions
- `RbacGate` — widget that shows/hides children based on permission check
- `MongoRbacProvider`, `FirebaseRbacProvider` — implementations (Firebase via `firebase.dart`)
- `PkSharingMixin` — Firestore sharing mixin (addMember, removeMember, getMembers, getMemberRole)
- `PkMember` — immutable member value type (userId, role, joinedAt)
- `PkShareRole` — role with permissions list
- `PkSharingConfig` — configurable field names for memberIds/roles
- `SharingException` — `PrimekitException` subtype for sharing failures

**RBAC pattern:**
```dart
await RbacService.instance.loadForUser(userId);
if (RbacService.instance.can(Permission.write('posts'))) { ... }
RbacGate(permission: Permission.admin(), child: AdminPanel())
```

**Sharing pattern:**
```dart
class MyRepo with PkSharingMixin {
  @override
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  // addMember('collection/docId', userId, 'editor')
  // removeMember('collection/docId', userId)
  // getMembers('collection/docId') → List<PkMember>
}
```

**Consumers:** PawTrack (sharing), Splitly (planned), Bullseye-Mobile-App (planned)

**Dependencies:** `core`, `cloud_firestore` (sharing mixin), firebase (conditional, RBAC providers)

**Maintenance:** Update when new permission type added, policy inheritance model changes, or sharing API changes.
