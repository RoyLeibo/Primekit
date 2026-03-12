# currency — Currency Conversion

**Purpose:** Real-time currency exchange rates with local caching.

**Key exports:**
- `CurrencyConverter` — convert amounts between currencies
- `CurrencyCache` — persistent rate caching (survives restarts)
- `CurrencyRateSource` — abstract interface
- `HttpCurrencyRateSource` — fetches from exchangerate-api
- `FirestoreCurrencyRateSource` — Firestore-backed rates (via `firebase.dart`)

**Active usage:** Splitly uses multi-source fallback: SharedPrefs → Firestore → HTTP.

**Dependencies:** `core`, `storage`, firebase (conditional)

**Maintenance:** Update when new rate source added.
