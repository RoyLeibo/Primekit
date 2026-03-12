# auth — Session & Token Management

**Purpose:** Auth session state machine, token persistence, HTTP interceptor, route guards.

**Key exports:**
- `SessionManager` — manages `SessionState`; call `.restoreSession()` at startup
- `SessionState` (sealed) — `SessionLoading` | `SessionAuthenticated` | `SessionUnauthenticated`
- `TokenStore` — abstract interface for token persistence (implement or use SecurePrefs default)
- `AuthInterceptor` — Dio interceptor; injects `Authorization: Bearer <token>` on every request
- `FirebaseAuthInterceptor` — Firebase-backed version (import via `firebase.dart`)
- `ProtectedRouteGuard` — GoRouter guard that redirects to login if unauthenticated
- `OtpService` — OTP validation helper

**Dependencies:** `core`, `storage` (SecurePrefs for token storage), `network` (Dio)

**Pattern:** `SessionManager` is a singleton via DI. Firebase implementation is in `firebase.dart`, not here.

**Maintenance:** Update when session state variants change or new guard type added.
