# permissions — Platform Permissions

**Purpose:** Platform-agnostic permission requests. Hides `permission_handler` from consumers.

**Key exports:**
- `PkPermission` — enum (Location, Camera, Contacts, Microphone, Notifications, Storage, etc.)
- `PkPermissionStatus` — enum (granted, denied, permanentlyDenied, restricted)
- `PermissionHelper` — batch permission requests
- `PermissionFlow` — multi-step permission request wizard
- `PermissionGate` — widget that gates a feature behind a required permission

**Platform implementations (auto-selected via conditional export):**
- Native iOS/Android: `permission_handler`
- Web: Browser Permissions API
- Other: Always-grants stub

**Dependencies:** permission_handler 12.0.0, web (conditional)

**Maintenance:** Update when new permission type added or `PermissionFlow` API changes.
