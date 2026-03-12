# email — Email Sending

**Purpose:** Templated email sending with retry queue.

**Key exports:**
- `EmailService` — main send interface
- `EmailProvider` — abstract backend
- `EmailQueue` — persists unsent emails for retry (survives app restart)
- `EmailMessage` — value type (to, subject, body, template data)
- `ContactFormMailer` — pre-built contact form template
- `VerificationMailer` — pre-built email verification template

**Exceptions:** `EmailException`

**Dependencies:** `core`, `storage`

**Maintenance:** Update when new mailer template added or queue strategy changes.
