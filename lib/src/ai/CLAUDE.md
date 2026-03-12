# ai — AI Integration

**Purpose:** Multi-provider AI abstraction. Swap OpenAI / Anthropic / Gemini without changing call sites.

**Key exports:**
- `AiService` — main inference interface; `.complete(prompt)`, `.stream(prompt)`
- `AiProvider` — abstract backend interface
- `OpenAiProvider` — OpenAI API implementation
- `AnthropicProvider` — Anthropic Claude API implementation

**Dependencies:** http, `core` (Result type)

**Active usage:** best_todo_list uses AI recommendations (50 calls/day metered at app level, not in Primekit).

**Note:** Usage metering/quotas are NOT handled in this module — implement at app level.

**Maintenance:** Update when new provider added or inference API changes.
