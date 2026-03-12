# calendar — Calendar Integration

**Purpose:** Calendar event management with Google Calendar support.

**Key exports:**
- `CalendarService` — main interface (create/update/delete events)
- `CalendarProvider` — abstract backend
- `CalendarEvent` — event value type (title, start, end, location, reminders)
- `GoogleCalendarProvider` — Google Calendar API implementation

**Dependencies:** googleapis 13.2.0, google_sign_in

**Active usage:** PawTrack syncs vaccine dates to Google Calendar.

**Maintenance:** Update when new calendar provider added or event fields change.
