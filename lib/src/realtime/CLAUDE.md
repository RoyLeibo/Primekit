# realtime — Real-Time Communication

**Purpose:** WebSocket channels for real-time messaging and presence tracking.

**Key exports:**
- `RealtimeManager` — manages multiple named channels
- `RealtimeChannel` — abstract interface for a messaging channel
- `MessageBuffer` — queues messages when offline, flushes on reconnect
- `PresenceTypes` — presence state types (online/offline/away)
- `WebSocketChannel` — WebSocket implementation
- `FirebaseRealtimeChannel` — Firebase Realtime Database impl (via `firebase.dart`)
- `FirebasePresenceService` — Firebase presence tracking (via `firebase.dart`)

**Dependencies:** web_socket_channel 3.0.1, firebase (conditional)

**Pattern:** Channel abstraction allows swapping transport (WebSocket ↔ Firebase) without changing consumers.

**Maintenance:** Update when new transport added or presence API changes.
