# speech -- Speech-to-Text

**Purpose:** Cross-platform speech recognition with automatic microphone permission handling via PrimeKit's permissions module.

**Key exports:**
- `PkSpeechService` -- singleton; `initialize()`, `startListening()`, `stopListening()`, `cancelListening()`, `availableLocales()`
- `PkSpeechResult` -- immutable result value type (`recognizedWords`, `isFinal`)
- `PkSpeechListenOptions` -- configuration for listening sessions (locale, duration, partial results)
- `PkSpeechLocale` -- locale value type with factories: `.english()`, `.hebrew()`, `.fromSystem()`, `.fromLocale()`
- `PkListeningDialog` -- reusable dialog widget with animated mic, real-time feedback; static `show()` method returns `Future<String?>`
- `PkListeningDialogConfig` -- dialog configuration (locale, prompt text, max duration)
- `SpeechException`, `SpeechPermissionException` -- `PrimekitException` subtypes

**Dependencies:** speech_to_text 7.0.0, permissions module (for mic permission), core (exceptions, logger)

**Maintenance:** Update when speech_to_text API changes or new locale factories added.
