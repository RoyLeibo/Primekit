# riverpod — Riverpod Helpers

**Purpose:** Base classes and utilities for Riverpod integration across Primekit.

**Key exports:**
- `PkAsyncNotifier<T>` — base class for async Riverpod notifiers; handles loading/error states
- `PkProviders` — factory helpers for common provider patterns
- `PkPaginationNotifierMixin<T>` — pagination-aware notifier mixin with bidirectional support
- `PkPaginationState<T>` — state class with `canLoadPrevious`, `canLoadMore`, `initialScrollIndex`
- `PkPageResult<T>` — return type for `fetchPageResult()` (bidirectional metadata)

**Dependencies:** flutter_riverpod 3.2.1

**Pattern:** Extend `PkAsyncNotifier` instead of `AsyncNotifier` to get Primekit error handling built in.

**Pagination modes:**
- **Forward-only:** Override `fetchPage(page, pageSize)` returning `List<T>`. Use `loadFirst()` + `loadMore()`.
- **Bidirectional:** Override `fetchPageResult(page, pageSize)` returning `PkPageResult<T>`. Use `loadFirst()` / `loadAt(page)` + `loadMore()` + `loadPrevious()`.

**Maintenance:** Update when new notifier base class added.
