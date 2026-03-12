# async_state — Async State Machine

**Purpose:** Loading/data/error state machine for async operations without full Riverpod complexity.

**Key exports:**
- `AsyncState<T>` (sealed) — `AsyncLoading` | `AsyncData<T>` | `AsyncError` | `AsyncRefreshing<T>`
- `AsyncStateNotifier<T>` — ChangeNotifier; use `.run(operation)`, `.refresh()`, `.reset()`
- `AsyncBuilder<T>` — widget that builds UI from AsyncState (handles all 4 states)
- `PaginatedState<T>` — extends AsyncState for cursor-based pagination

**Pattern:** Use `when()`/`maybeWhen()` for exhaustive handling. Stale results filtered via operation IDs.

**Dependencies:** flutter (ChangeNotifier)

**Maintenance:** Update when new state variant added or builder API changes.
