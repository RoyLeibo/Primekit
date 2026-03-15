# module: chat — Reusable Group Chat Building Blocks

## Public API

| Export | Purpose |
|--------|---------|
| `Message`, `MessageReadStatus` | Immutable entities |
| `MessageRepository` | Abstract repository interface |
| `ChatService` | High-level send operations with validation |
| `ChatThemeData`, `ChatTheme` | InheritedWidget theming configuration |
| `ChatMessageList` | Composable message list with date separators + sender grouping |
| `MessageBubble`, `ChatInput` | Core chat widgets |
| `TypingIndicator`, `SystemMessageWidget` | Supporting widgets |
| `ReactionPicker`, `ReactionDisplay` | Reaction UI |
| `ReplyPreview`, `InlineReplyBubble` | Reply UI |
| `chat_providers.dart` | Riverpod providers (must be overridden in ProviderScope) |

## Firebase (import via `package:primekit/firebase.dart`)

| Class | Purpose |
|-------|---------|
| `FirestoreMessageDataSource` | Firestore message CRUD + streams |
| `FirestoreTypingDataSource` | Firestore typing indicators |
| `FirestoreMessageRepository` | Repository with error mapping to ChatException |

## Non-obvious

- `SystemMessageType` is `String`-based (not an enum) — apps define custom types
- Sender name resolution via `ChatThemeData.senderNameBuilder` callback
- Host app wraps chat UI in `ChatTheme` InheritedWidget for visual customization
- `ChatMessageList.systemMessageBuilder` lets apps render custom system messages (e.g. expense cards)
