# scheduling — Recurrence & Schedule Computation

**Purpose:** Pure-function schedule calculator for recurring events. Domain-agnostic (medications, tasks, habits, reminders).

**Key exports:**
- `RecurrenceMode` — enum: interval, daily, weekly, monthly
- `RecurrenceRule` — immutable rule (mode, intervalDays, dailyTimes, daysOfWeek, dayOfMonth)
- `ScheduleTimeOfDay` — hour+minute value type (framework-agnostic)
- `ScheduleSlot` — value type (scheduledTime, isCompleted, slotKey)
- `ScheduleCalculator` — static pure functions:
  - `generateSlots()` — all slots in a date range
  - `nextUnfilledSlot()` — first incomplete slot
  - `computeNextDueDate()` — next due DateTime
  - `todaysSlots()` — today's slots with completion status
  - `isCourseComplete()` — whether all course slots are filled
  - `courseDayNumber()` — 1-based day in course
  - `formatSchedule()` — human-readable description

**Dependencies:** None (pure Dart, no Flutter or Firebase).

**Consumers:** PawTrack (medications), best_todo_list (recurring tasks).

**Maintenance:** Update when new RecurrenceMode added or calculator API changes.
