# statistics -- Completion Analytics

**Purpose:** Generic completion/creation event tracking with pure-function calculators and local storage.

**Key exports:**
- `PkCompletionEvent` -- immutable event: entityId, entityType, timestamp, dueDate, wasOnTime, priority, tags, metadata
- `PkCreationEvent` -- immutable creation event: entityId, entityType, timestamp
- `PkStatsCalculator` -- static pure functions: completionRate, trendsPerDay, trendsPerWeek, hourDistribution, currentStreak, longestStreak, productivityScore
- `PkStatsStore` -- abstract storage interface: trackCompletion, trackCreation, getEvents, getEventsInRange
- `SharedPrefsStatsStore` -- SharedPreferences implementation (local, privacy-first, capped at maxEvents)

**Dependencies:** `core` (exceptions, logger), `shared_preferences`.

**Consumers:** best_todo_list.

**Maintenance:** Update when event model fields change or new calculator methods added.
