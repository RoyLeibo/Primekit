# core — Foundational Types

**Purpose:** Exceptions, Result type, config, logging. No dependencies — all other modules depend on this.

**Key exports:**
- `PrimekitException` (sealed) — base for all module exceptions; has `.userMessage` for UI display
  - Subtypes: `NetworkException`, `AuthException`, `BillingException`, `ValidationException`, + more
- `Result<S, F>` — discriminated union (Success/Failure); use `.when()`, `.map()`, `.asyncMap()`, `.or()`
- `PrimekitConfig` — singleton; call `PrimekitConfig.initialize()` in `main()` before anything else
- `PrimekitLogger` — structured logging with configurable levels

**Pattern:** Sealed classes for exhaustive pattern matching everywhere in Primekit.

**Maintenance:** Update when new exception subtype added or Result API changes.
