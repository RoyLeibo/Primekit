# riverpod — Riverpod Helpers

**Purpose:** Base classes and utilities for Riverpod integration across Primekit.

**Key exports:**
- `PkAsyncNotifier<T>` — base class for async Riverpod notifiers; handles loading/error states
- `PkProviders` — factory helpers for common provider patterns
- `PkPaginationNotifier<T>` — pagination-aware notifier with cursor support

**Dependencies:** flutter_riverpod 3.2.1

**Pattern:** Extend `PkAsyncNotifier` instead of `AsyncNotifier` to get Primekit error handling built in.

**Maintenance:** Update when new notifier base class added.
