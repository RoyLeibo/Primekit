# ai — AI Integration

**Purpose:** Multi-provider AI abstraction + usage quota metering.

**Key exports:**
- `AiService` — main inference interface; `.complete(prompt)`
- `AiProvider` — abstract backend interface
- `OpenAiProvider` — OpenAI API implementation
- `AnthropicProvider` — Anthropic Claude API implementation
- `AiQuotaService` — Firestore-backed daily usage quota (configurable limit, auto-reset)
- `AiQuotaConfig` — configuration for quota service (dailyLimit, warningThreshold, collection)
- `AiQuotaSnapshot` — immutable snapshot of usage state (used, remaining, percentageUsed)

**Dependencies:** http, cloud_firestore, `core` (Result type, PrimekitException, PrimekitLogger)

**Exceptions:** `AiQuotaException`, `AiQuotaExceededException` (defined in core/exceptions.dart)

**Active usage:** best_todo_list delegates AI quota enforcement to `AiQuotaService` via its `AIUsageLimiter` wrapper.

**Maintenance:** Update when new provider added, inference API changes, or quota logic changes.
