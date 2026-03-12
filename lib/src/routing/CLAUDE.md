# routing — Navigation & Deep Links

**Purpose:** GoRouter guards, deep link parsing, and navigation utilities.

**Key exports:**
- `RouteGuard` — abstract interface for route protection
- `ProtectedRouteGuard` — auth-based guard (redirects to login if `SessionState` is unauthenticated)
- `DeepLinkHandler` — parses and routes incoming deep links
- `NavigationLogger` — logs route transitions for analytics
- `TabStateManager` — persists tab navigation state across restarts

**Dependencies:** go_router 17.1.0

**Pattern:** Compose multiple guards: `[AuthGuard(), PermissionGuard('feature')]`

**Maintenance:** Update when new guard type added or deep link handling changes.
