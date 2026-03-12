# audit — Audit Trail

**Purpose:** Immutable append-only audit log for compliance and debugging.

**Key exports:**
- `AuditLogService` — singleton; call `.log(event)` to append
- `AuditEvent` — immutable value type: `actor`, `action`, `resource`, `timestamp`, `metadata`
- `AuditQuery` — query builder for retrieving audit history
- `AuditBackend` — abstract storage interface
- `InMemoryAuditBackend` — testing/dev backend
- `FirestoreAuditBackend` — production backend (import via `firebase.dart`)

**Pattern:** Event sourcing — never update or delete audit records.

**Dependencies:** `core`, firebase (conditional)

**Maintenance:** Update when new query capability added or event schema changes.
