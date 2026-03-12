# rbac — Role-Based Access Control

**Purpose:** Permission checking and policy enforcement. Backend-agnostic with Firebase/Mongo implementations.

**Key exports:**
- `RbacService` — singleton; load policies then check permissions
- `RbacPolicy` — policy definition (roles, permissions, inheritance hierarchy)
- `RbacProvider` — abstract interface for loading policies
- `Permission` — value type with `Permission.write('posts')`, `Permission.admin()`, etc.
- `Role` — role definition with assigned permissions
- `RbacGate` — widget that shows/hides children based on permission check
- `MongoRbacProvider`, `FirebaseRbacProvider` — implementations (Firebase via `firebase.dart`)

**Pattern:**
```dart
await RbacService.instance.loadForUser(userId);
if (RbacService.instance.can(Permission.write('posts'))) { ... }
// In widgets:
RbacGate(permission: Permission.admin(), child: AdminPanel())
```

**Planned usage:** Splitly (admin/member group roles), Bullseye-Mobile-App

**Dependencies:** `core`, firebase (conditional)

**Maintenance:** Update when new permission type added or policy inheritance model changes.
