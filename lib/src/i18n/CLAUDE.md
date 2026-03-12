# i18n — Internationalization

**Purpose:** Locale management and locale-aware formatting.

**Key exports:**
- `LocaleManager` — current locale state management
- `DateFormatter` — locale-aware date/time formatting
- `CurrencyFormatter` — locale-aware currency formatting
- `PluralHelper` — pluralization rules

**Dependencies:** intl 0.20.2

**Active usage:** PawTrack uses `LocaleManager`.

**Note:** best_todo_list uses full ARB-based localization (Hebrew/RTL) separately — `kosher_dart` for Hebrew calendar.

**Maintenance:** Update when new formatting helper added.
