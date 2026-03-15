# i18n_hebrew — Hebrew Calendar & Jewish Holidays

**Purpose:** Hebrew date formatting and Jewish holiday computation via `kosher_dart`.

**OPTIONAL module** — not exported from `primekit.dart`. Import via `package:primekit/i18n_hebrew.dart`.

**Key exports:**
- `PkHebrewDateFormatter` — `format()`, `formatShort()`, `hebrewYear()`, `hebrewMonth()`
- `PkJewishHolidayService` — `getHolidays()`, `isShabbat()`, `getShabbatTimes()`, `nextHoliday()`
- `PkJewishHoliday` — immutable holiday model with `name`, `hebrewName`, `date`, `isYomTov`, `category`
- `PkJewishHolidayCategory` — enum: `major`, `minor`, `fast`, `modern`, `shabbat`

**Dependencies:** `kosher_dart ^2.0.18`

**Active usage:** best_todo_list

**Maintenance:** Update when holiday map entries added or kosher_dart API changes.
